#!/bin/bash
echo "http://127.0.0.1:8888" 
docker run -it --rm \
     -v "$(pwd)":/home/omniscape \
     -p 8888:8888 \
     vlandau/jupyter:julia-python3