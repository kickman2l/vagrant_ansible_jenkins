#!/bin/bash

function start_vm
{
    cd $path
    current_status=$(vagrant status | grep default | awk '{print $2}')

    if [ $current_status == "running" ]; then
        changed=false
        status=$current_status
    else
        output=$(vagrant up 2>&1 | python -c 'import json,sys; print json.dumps(sys.stdin.read())')
        if [ $? -ne 0 ]; then
        printf '{"failed": true, "msg": "error starting vm", "output": %s}' "$output"
        exit 1
    fi
        status=$(vagrant status | grep default | awk '{print $2}')
        changed=true
    fi

    msg="vm is running"
    failed=false

    RES_BOX_STATE=$(vagrant status | grep virtualbox | awk '{print $2}')
    RES_BOX_PORT=$(vagrant ssh-config | grep Port | awk '{print $2}' 2>/dev/null)
    RES_BOX_IPADDR=$(vagrant ssh -c "hostname -I | cut -d' ' -f2" 2>/dev/null)
    RES_BOX_SSH_PATH=$(vagrant ssh-config | grep IdentityFile | awk '{print $2}' 2>/dev/null)
    RES_BOX_USR=$(vagrant ssh-config | grep -w User | awk '{print $2}' 2>/dev/null)
    RES_BOX_OS=$(vagrant ssh -c "cat /etc/redhat-release" 2>/dev/null)
    RES_BOX_MEM=$(vagrant ssh -c "cat /proc/meminfo | grep MemTotal | awk '{print \$2 \$3}'" 2>/dev/null)

    printf '{"changed": true, "failed": false, "msg": "Well Done!", "RES_BOX_STATE": "%s", "RES_BOX_PORT": "%s", "RES_BOX_IPADDR": "%s", "RES_BOX_SSH_PATH": "%s", "RES_BOX_USR": "%s", "RES_BOX_OS": "%s", "RES_BOX_MEM": "%s" }' "$RES_BOX_STATE" "$RES_BOX_PORT" "$RES_BOX_IPADDR" "$RES_BOX_SSH_PATH" "$RES_BOX_USR" "$RES_BOX_OS" "$RES_BOX_MEM"
    exit 0
}

function stop_vm
{
    cd $path
    current_status=$(vagrant status | grep default | awk '{print $2}')
    if [ $current_status == "stopped" ]; then
        changed=false
        status=$current_status
    else
        output=$(vagrant halt 2>&1 | python -c 'import json,sys; print json.dumps(sys.stdin.read())')
        if [ $? -ne 0 ]; then
            printf '{"failed": true, "msg": "error stopping vm", "output": %s}' "$output"
            exit 1
        fi
    fi
    msg="vm is stopped"
    status="stopped"
}

function destroy_vm
{
    cd $path
    current_status=$(vagrant status | grep default | awk '{print $2}')
    if [ $current_status == "not created" ]; then
        changed=false
        status=$current_status
    else
        output=$(vagrant destroy 2>&1 | python -c 'import json,sys; print json.dumps(sys.stdin.read())')
        if [ $? -ne 0 ]; then
            printf '{"failed": true, "msg": "error destroying vm", "output": %s}' "$output"
            exit 1
        fi
    fi
    msg="vm is destroyed"
    status="not created"
}

source $1

if [ -z "$path" ]; then
    printf '{"failed": true, "msg": "missing required argument: path"}'
    exit 1
fi

if [ -z "$state" ]; then
    printf '{"failed": true, "msg": "missing required argument: state"}'
    exit 1
fi

if [ ! -d "$path" ]; then
    printf '{"failed": true, "msg": "Invalid path"}'
    exit 1
fi

changed=false

case $state in
    started)
        start_vm
    ;;
    stopped)
        stop_vm
    ;;
    destroyed)
        destroy_vm
    ;;
    *)
        printf '{"failed": true, "msg": "invalid state: %s"}' "$state"
        exit 1
    ;;
esac

printf '{"changed": true, "failed": false, "msg": "%s", "state": "%s" }' "$msg" "$status"
exit 0