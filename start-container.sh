#!/bin/bash

sudo docker volume create env-data-$1 \
&& sudo docker run -d --name $1 \
    --hostname $1 \
    --network gdmu-cxb \
    -p $2:22 -p $3:8000 \
    -v env-data-$1:/data \
    seeleclover/ubuntu:na-dev \
&& sudo docker exec -it $1 ./setPassword.sh $4
