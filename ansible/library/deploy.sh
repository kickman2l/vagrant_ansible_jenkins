#!/bin/bash

# Deploy war to tomcat

source $1

if [ -z "$war" ]; then
    printf '{"failed": true, "msg": "missing required argument: war"}'
    exit 1
fi
if [ -z "$url" ]; then
    printf '{"failed": true, "msg": "missing required argument: url"}'
    exit 1
fi
if [ -z "$user" ]; then
    printf '{"failed": true, "msg": "missing required argument: user"}'
    exit 1
fi
if [ -z "$password" ]; then
    printf '{"failed": true, "msg": "missing required argument: password"}'
    exit 1
fi
if [ ! -f "$war" ]; then
    printf '{"failed": true, "msg": "war-file not found"}'
    exit 1
fi

changed=false
failed=false

warfile=`basename $war`
apppath=${warfile%.*}

output=$(curl -T "$war" -u $user:$password "$url/manager/text/deploy?path=/$apppath&update=true" 2>&1 | python -c 'import json,sys; print json.dumps(sys.stdin.read())')

if [ $? -ne 0 ]; then
	printf '{"failed": true, "msg": "deployment error", "output": %s}' "$output"
	exit 1
else
	changed=true
	printf '{"changed": %s, "failed": %s, "msg": "OK - Deployed application at context path /%s", "appurl": "%s"}' "$changed" "$failed" "$apppath" "$url/$apppath"
	exit 0
fi
