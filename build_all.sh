#!/bin/bash

#export platform="linux/arm64/v8,linux/amd64"
export platform="linux/amd64"

tag="0.8.6"

# Only the versioned tag is pushed unless PUSH_LATEST=1, so a new version can be tested
# (e.g. by pointing a PrairieLearn question at ctessum/<image>:${tag}) before it becomes latest.

for image in pl-julia-datascience-base pl-julia-datascience-grader pl-julia-datascience-pluto-workspace
do
    echo "------------------- Building ${image} -------------------"
    cd $image
    tags=(--tag ctessum/${image}:${tag})
    if [ "${PUSH_LATEST:-0}" = "1" ]; then
        tags+=(--tag ctessum/${image}:latest)
    fi
    # The grader and workspace images are built on the base image with the same version tag
    # (not "latest"), so that they pick up the base image that was just pushed.
    docker buildx build --platform $platform --push "${tags[@]}" --build-arg BASE_TAG=${tag} .
    cd ..
done
