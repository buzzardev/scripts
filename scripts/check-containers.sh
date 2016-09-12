#!/usr/bin/env bash

set -e

check_container () {
    local CONTAINER_NAME CONTAINER_PORT MAX_FAILS=20 TIME_BEGIN=$(date +%s) SLEEP=1

    while [[ ${1} ]]; do
        local PARAMETER="${1:2}"

        case "${PARAMETER}" in
            container)
                CONTAINER_NAME=${2}
                shift
                ;;
            port)
                CONTAINER_PORT=${2}
                shift
                ;;
            timeout)
                MAX_FAILS=${2}
                shift
                ;;
            *)
                echo "Unknown parameter \"${PARAMETER}\"" >&2
                exit 1
        esac

        if ! shift; then
            echo 'Missing argument' >&2
            exit 1
        fi
    done

    CONTAINER_IP=$(docker-compose exec -T "${CONTAINER_NAME}" getent hosts "${CONTAINER_NAME}" | awk '{ print $1 }')
    if test -z "${CONTAINER_IP}"; then
        echo -e "\033[1;31;47mCould not detect the IP address for container ${CONTAINER_NAME}\033[0m"
        exit 1
    fi
    echo "Checking container ${CONTAINER_NAME} on ${CONTAINER_IP}:${CONTAINER_PORT}"
    FAILS=0
    while true; do
        if ! nc -z -w 1 ${CONTAINER_IP} ${CONTAINER_PORT}; then
            FAILS=$[FAILS + 1]
            if test ${FAILS} -gt ${MAX_FAILS}; then
                echo -e "\033[1;31;47mWaiting too long for the ${CONTAINER_NAME} container (timeout)\033[0m"
                exit 1
            fi
            sleep ${SLEEP}
            continue
        fi
        break
    done
    return 0
}

if ! type "jq" &> /dev/null; then
    sudo apt-get update && apt-get install -y jq
fi

SERVICES=$(docker-compose config --services)
#PORTS=$(netstat -lntu | grep 'LISTEN' | awk '{ print $4 }' | sed 's/0.0.0.0:\\\|::://' | sort -u)

for SERVICE in ${SERVICES}
do
    PORTS=$(docker inspect --format="{{json .Config.ExposedPorts}}" "$(docker-compose ps -q "${SERVICE}")" | grep -v "null" | jq -r 'keys[]' | sed 's/\\\/tcp//')
    for PORT in ${PORTS}
    do
        if test -n "$(docker-compose port "${SERVICE}" "${PORT}" 2>/dev/null)"; then
            check_container --container "${SERVICE}" --port "${PORT}" --timeout 60
        fi
    done
done
