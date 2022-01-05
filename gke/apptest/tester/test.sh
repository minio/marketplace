#!/bin/bash

namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
endpoint="http://console.$namespace.svc.cluster.local:9090"
echo GET $endpoint
http_status_code=$(curl -o /dev/null -s -w "%{http_code}\n" $endpoint)
echo "Expected http status code: 200"
echo "Actual http status code: $http_status_code"
if [[ "$http_status_code" == "200" ]]; then
  echo SUCCESS
else
  echo FAILURE
  exit 1
fi
