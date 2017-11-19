#!/bin/bash

docker-compose stop && docker-compose rm -f && docker build --rm -t tfatykhov/nginx-proxy:1.0 . && docker-compose  up -d && echo "Build prcess completed.. runninng logs" && docker-compose logs -f