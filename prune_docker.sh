#!/bin/sh

docker image prune -a -f --filter="until=48h"
docker container prune -f --filter="until=48h"
docker volume prune -f --filter="until=48h"
