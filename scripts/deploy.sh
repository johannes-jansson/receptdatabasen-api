#!/bin/bash

set -e

# This script is called from the post-receive hook, upon deployment.

echo "Deploying ${NEWREV:0:6}..."
(cd frontend && docker build -t receptdatabasen_frontend_builder .) 
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
