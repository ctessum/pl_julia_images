#!/bin/bash

#export platform="linux/arm64/v8,linux/amd64"
export platform="${PLATFORM:-linux/amd64}"

tag="0.11.0"

# Only the versioned tag is pushed unless PUSH_LATEST=1, so a new version can be tested
# (e.g. by pointing a PrairieLearn question at ctessum/<image>:${tag}) before it becomes latest.
# (The GitHub Actions workflow "Build and push images" does the same on native amd64 and arm64 runners.)

# Both images are built from the Dockerfile in this directory (targets "grader" and "workspace").
for target in grader:pl-julia-datascience-grader workspace:pl-julia-datascience-pluto-workspace
do
    stage=${target%%:*}
    image=${target##*:}
    echo "------------------- Building ${image} -------------------"
    tags=(--tag ctessum/${image}:${tag})
    if [ "${PUSH_LATEST:-0}" = "1" ]; then
        tags+=(--tag ctessum/${image}:latest)
    fi
    docker buildx build --platform $platform --target $stage --push "${tags[@]}" .
done
