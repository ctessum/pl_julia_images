A container with Julia and Pluto.jl

To build:

``` bash
docker buildx build --platform linux/arm64/v8,linux/amd64 --push --tag ctessum/pl-julia-datascience-pluto-workspace:latest .
```

To run:

``` bash
docker run --rm -it -p 1234:1234 --user 1001:1001 \
    -v "`pwd`:/home/julia/workspace" \
    ctessum/pl-julia-datascience-pluto-workspace:latest

OR

docker run --rm -it -p 1234:1234 --user 1001:1001 \
    ctessum/pl-julia-datascience-pluto-workspace:latest

```

```
sudo docker run -it --rm -p 3000:3000 -v /your/local/course/directory:/course -v /your/local/jobs/directory:/jobs -e HOST_JOBS_DIR=/your/local/jobs/directory -v /var/run/docker.sock:/var/run/docker.sock --add-host=host.docker.internal:172.17.0.1 prairielearn/prairielearn /bin/bash -c '/PrairieLearn/tools/start_workspace_tmux.sh'

docker run -it --rm -p 3000:3000 \
    -v /Users/ctessum/code/PrairieLearn:/PrairieLearn \
    -v "/Users/ctessum/Google Drive/uiuc/teaching/data_science/pl-cee498ds:/course" \
    -v "$HOME/pl_ag_jobs:/jobs" \
    -e HOST_JOBS_DIR="$HOME/pl_ag_jobs" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    prairielearn/prairielearn:arm \
    /bin/bash -c '/PrairieLearn/tools/start_workspace_tmux.sh'
```

https://prairielearn.slack.com/archives/C266KEH9A/p1631562551420900


Check out the gymnastics we did with the RStudio workspace. There are some notes in the dockerfile. https://github.com/PrairieLearn/PrairieLearn/tree/master/workspaces/rstudio

What I try to do is reset permissions on everything in the user's home directory to be owned by 1001:1001 (and actually change the user's UID to be 1001 as well). There's a part of the dockerfile that does that explicitly (once, during the build).

Some workspaces have scripts that try to do this dynamically when the container starts, but that can be prone to timeout issues

NB --add-host should only be used in linux, so macos users should remove it