#!/bin/bash

verify_aws_extras_dir () {
    mkdir -p ~/.aws/extras
}

get_default_key () {
    local key=$(gpgconf --list-options gpg | awk -F: '$1 == "default-key" {print substr($10, 2)}')
    echo $key
}

get_encrypt_key () {
    verify_aws_extras_dir
}

encrypt_pipe () {
    declare defkey
    if (( $1 )); then
        defkey=$(get_default_key)
        if [[ ! "$defkey" ]]; then
            echo "No default gpg key" >&2
            return 1
        fi
    fi
    if [[ "$2" ]]; then
        if (( $1 )); then
            gpg --for-your-eyes-only --output $2 -e -r $defkey
        else
            touch $2 && chmod 600 $2 && dd status=none of=$2
        fi
    elif (( $1 )); then
        gpg --for-your-eyes-only --no-tty -e -r $defkey
    else
        cat
    fi
}

decrypt_pipe () {
    if (( $1 )); then
        gpg --for-your-eyes-only --no-tty -d 2>/dev/null
    else
        cat
    fi
}

test_gpg () {
    [[ "$( echo Hello World | encrypt_pipe 1 | decrypt_pipe 1 )" == "Hello World" ]]
}
