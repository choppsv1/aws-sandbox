#!/bin/bash

declare srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${srcdir}/awsutil.sh

user=""

usage ()
{
    echo "create-user.sh [-De] user" >&2
    exit 1;
}

mkdir -p ~/.aws/userdb

delete=0
usegpg=0
while getopts "De" arg; do
    case $arg in
        D)
            delete=1
            ;;
        e)
            if ! test_gpg; then
                echo "gpg not functioning properly" >&2
                exit 1
            fi
            usegpg=1
            ;;
        *)
            echo "Error: Bad option $arg" >&2
            usage
            ;;
    esac
done
shift $((OPTIND-1))
user=$1

if (( $# != 1 )); then
   echo "Error: single user name required" >&2
   usage
fi

userfile=~/.aws/userdb/$user.json.gpg

if [[ -e $userfile ]] && (( ! delete )); then
   echo "Error: userfile $userfile for $user already created" >&2
   exit 1
elif [[ ! -e $userfile ]] && (( delete )); then
    if ! aws iam get-user --user-name $user > /dev/null 2>&1; then
       echo "Error: user userfile $userfile and user $user doesn't exist" >&2
       exit 1
    fi
fi

if (( delete )); then
    declare keys="$(aws iam list-access-keys --user-name $user | jq -r '.AccessKeyMetadata[].AccessKeyId')"
    for key in $keys; do
        echo "Deleting access-key $key"
        aws iam delete-access-key --user-name $user --access-key-id $key
    done
    echo "Deleting user $user"
    aws iam delete-user --user-name $user
    rm -f $userfile
    exit 0
fi

echo "Creating User: $user"
(aws iam create-user --user-name $user && aws iam create-access-key --user-name $user) \
    | jq -s '.[0] * .[1]' | encrypt_pipe $usegpg $userfile
