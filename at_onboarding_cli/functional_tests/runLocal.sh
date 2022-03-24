#!/bin/bash

echo "Getting dependencies" && dart pub get
#echo "Pulling docker image" && sudo docker-compose pull
echo "Starting docker-compose" && sudo docker-compose up -d
dart run check_docker_readiness.dart
echo "Executing pkamLoad" && sudo docker exec functional_tests_virtualenv_1 supervisorctl start pkamLoad
dart run check_test_env.dart
echo "Running tests" && dart test --concurrency=1
echo "Killing docker container" && sudo docker-compose down