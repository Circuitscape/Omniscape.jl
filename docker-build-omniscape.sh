#!/usr/bin/env bash
mkdir build-dir
cd build-dir
cp ../Dockerfile Dockerfile
docker build . -t vlandau/omniscape:0.1.2
cd ..
rm -rf build-dir