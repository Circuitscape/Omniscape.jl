#!/bin/bash
xhost local:root
docker run -i -d --rm --ipc "host" -v /tmp/.X11-unix/:/tmp/.X11-unix/ \
              	   -v $HOME/.atom:/root/.atom \
              	   -v "$(pwd)":/home/omniscape \
              	   -e DISPLAY \
              	   omniscape-atom-env:latest