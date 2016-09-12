#!/usr/bin/env bash

set -e

if test -f .env.dist; then
    if test ! -f .env; then
        cp ".env.dist" ".env"
    else

        cp ".env.dist" ".env.merge"
        while IFS="=" read -r -a LINE
        do
            KEY="${LINE[@]::1}"
            VALUE="${LINE[@]:1}"
            if test -n "${KEY}" && test -n "${VALUE}"; then
                if test 0 == $(grep -c "${KEY}=${VALUE}" ".env.merge"); then
                    if test 1 == $(grep -c "${KEY}=" ".env.merge"); then
                        ESCAPE_KEY=$(echo "${KEY}" | sed 's/\//\\\//g')
                        ESCAPE_VALUE=$(echo "${VALUE}" | sed 's/\//\\\//g')
                        sed -i -e "s/^${KEY}\s*\=\s*.*\$/${ESCAPE_KEY}=${ESCAPE_VALUE}/" ".env.merge"
                        echo -e "${KEY}=\033[4m${VALUE}\033[0m"
                    else
                        echo "${KEY}=${VALUE}" >> ".env.merge"
                        echo -e "\033[4m${KEY}=${VALUE}\033[0m"
                    fi
                fi
            fi
        done < ".env"
        rm ".env"
        mv ".env.merge" ".env"
    fi

fi
