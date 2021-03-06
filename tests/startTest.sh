#!/bin/bash
set -e

POD_NAME="testMycenae"

docker rm -f ${POD_NAME} || true

pod_arguments=(
	'-it'
    '--detach'
    '--name' "${POD_NAME}"
    '--volume' "${GOPATH}/src:/var/go/src"
    '--network=timeseriesNetwork'
)

# build it using: "docker build -t centos7-go:v1 ."
docker run "${pod_arguments[@]}" centos7-go:v1

scylla1=$(docker inspect --format "{{ .NetworkSettings.Networks.timeseriesNetwork.IPAddress }}" scylla1)
scylla2=$(docker inspect --format "{{ .NetworkSettings.Networks.timeseriesNetwork.IPAddress }}" scylla2)
scylla3=$(docker inspect --format "{{ .NetworkSettings.Networks.timeseriesNetwork.IPAddress }}" scylla3)
solr=$(docker inspect --format "{{ .NetworkSettings.Networks.timeseriesNetwork.IPAddress }}" solr1)

mycenaePodId=$(docker ps -f 'name=mycenae1' -q)
if [ -z "$mycenaePodId" ]; then
    mycenae=$(ifconfig docker0 | grep 'inet addr' | awk -F':' '{print $2}' | awk '{print $1}')
else
    mycenae=$(docker inspect --format "{{ .NetworkSettings.Networks.timeseriesNetwork.IPAddress }}" mycenae1)
fi

docker exec testMycenae /bin/sh -c "echo $scylla1 scylla1 >> /etc/hosts"
docker exec testMycenae /bin/sh -c "echo $scylla2 scylla2 >> /etc/hosts"
docker exec testMycenae /bin/sh -c "echo $scylla3 scylla3 >> /etc/hosts"
docker exec testMycenae /bin/sh -c "echo $solr solr >> /etc/hosts"
docker exec testMycenae /bin/sh -c "echo $mycenae mycenae >> /etc/hosts"

docker exec testMycenae go test -timeout 20m -v '/var/go/src/github.com/uol/mycenae/tests/'
