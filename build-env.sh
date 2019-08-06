#!/bin/bash
mkdir build-dir
cd build-dir
cp ../Dockerfile Dockerfile
docker build . -t omniscape-env
cd ..
rm -rf build-dir