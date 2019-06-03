#!/bin/bash
xhost local:root
docker run -d --rm -v /tmp/.X11-unix/:/tmp/.X11-unix/ \
              	   -v $HOME/.atom:/home/atom/.atom \
              	   -v "$(pwd)":/home/atom/omniscape \
              	   -e DISPLAY \
              	   vlandau/juno-ide:latest