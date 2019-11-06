#!/usr/bin/env bash
mkdir build-dir
cd build-dir
cp ../Dockerfile Dockerfile
docker build . -t vlandau/omniscape:latest
cd ..
rm -rf build-dir