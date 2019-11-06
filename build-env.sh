#!/bin/bash
mkdir build-dir
cd build-dir

cp ../dev.Dockerfile Dockerfile
docker build . -t omniscape-dev

cd ..
rm -rf build-dir