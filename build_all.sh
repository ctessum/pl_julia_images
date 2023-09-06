#!/bin/bash

#export platform="linux/arm64/v8,linux/amd64"
#export platform="linux/arm64/v8"
export platform="linux/amd64" # Cross-compilation not working.

tag="0.4.2"


#for image in pl-julia-datascience-pluto-workspace
for image in pl-julia-datascience-base pl-julia-datascience-grader pl-julia-datascience-pluto-workspace
do
    echo "------------------- Building ${image} -------------------"
    cd $image
    docker buildx build --platform $platform --push --tag ctessum/${image}:latest --tag ctessum/${image}:${tag} .
    cd ..
done

# 0.2.0 time to working HW1: 12:41 (laggy even after this)
# 0.3.0 time to working HW1: 6:41
# 0.4.0 time to working HW1: 3:45

# gcloud 
# 0.2.0: 10s startup, 3.4GB memory
# 0.3.0: 18s startup, 3.4GB memory
# 0.3.1: 13s startup, 3.4GB memory
# 0.4.0: 16s startup, ~600MB memory?