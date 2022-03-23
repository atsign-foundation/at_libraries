#!/bin/bash

echo "Getting dependencies" && dart pub get
#echo "Pulling docker image" && sudo docker-compose pull
echo "Starting docker-compose" && sudo docker-compose up -d
echo "Executing pkamLoad" && sudo docker exec functional_tests_virtualenv_1 supervisorctl start pkamLoad
echo "Running tests" && dart test
echo "Killing docker container" && docker-compose down