#!/bin/bash

user=""

usage ()
{
    echo "create-user.sh [-u user]"
    exit 1;
}

mkdir -p ~/.aws/userdb

delete=0
while getopts "Du:" OPTION; do
    case $OPTION in
        D)
            delete=1
            ;;
        u)
            user=$OPTARG
            ;;
        *)
            echo "Error: Bad option $arg"
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ ! $user ]]; then
   echo "Error: user name required"
   usage
fi

userfile=~/.aws/userdb/$user.json
if [[ -e $userfile ]] && (( ! delete )); then
   echo "Error: user $user already created"
   exit 1
elif [[ ! -e $userfile ]] && (( delete )); then
    if ! aws iam get-user --user-name $user > /dev/null 2>&1; then
       echo "Error: user $user not created yet"
       exit 1
    fi
fi
if (( delete )); then
    set -e
    if [[ -e $userfile ]]; then
       if AKEY="$(jq -r .AccessKey.AccessKeyId ~/.aws/userdb/foobar.json)"; then
           $(aws iam delete-access-key --user-name $user --access-key-id $AKEY)
       fi
    fi
    aws iam delete-user --user-name $user
    rm -f $userfile
    exit 0
fi

echo "Creating User: $user"

set -e
USERDATA="$(aws iam create-user --user-name $user)"
KEYDATA="$(aws iam create-access-key --user-name $user)"
touch $userfile
chmod 600 $userfile

echo $USERDATA $KEYDATA | jq -s '.[0] * .[1]' >> $userfile
