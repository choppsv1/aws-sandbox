#!/bin/bash

bucket=""
region=""$(aws configure get default.region)""
private=true

usage ()
{
    echo "create-backup-bucket.sh [-p] [-b bucketname] [-r region]"
    exit 1;
}

while getopts "b:pr:" OPTION; do
    case $OPTION in
        b)
            bucket=$OPTARG
            ;;
        p)
            private=false
            ;;
        r)
            region=$OPTARG
            ;;
        *)
            echo "Error: Bad option $arg"
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ ! $bucket ]]; then
   echo "Error: bucket name required"
   usage
fi

echo "Creating Bucket: $bucket Region: $region Private: $private"

aws s3api create-bucket --bucket $bucket --acl private --region $region --create-bucket-configuration "LocationConstraint=$region"
aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration=file://<(cat <<EOF
{
    "BlockPublicAcls": $private,
    "IgnorePublicAcls": $private,
    "BlockPublicPolicy": $private,
    "RestrictPublicBuckets": $private
}
EOF
)
