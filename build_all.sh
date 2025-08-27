#!/bin/bash

export platform="linux/arm64/v8,linux/amd64"

tag="0.7.0"

for image in pl-julia-datascience-base pl-julia-datascience-grader pl-julia-datascience-pluto-workspace
do
    echo "------------------- Building ${image} -------------------"
    cd $image
    docker buildx build --platform $platform --push --tag ctessum/${image}:latest --tag ctessum/${image}:${tag} .
    cd ..
done