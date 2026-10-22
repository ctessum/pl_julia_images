# syntax=docker/dockerfile:1
#
# Builds the Julia data science images:
#
#   docker buildx build --target workspace ...   (Pluto workspace, ctessum/pl-julia-datascience-pluto-workspace)
#   docker buildx build --target grader ...      (autograder, ctessum/pl-julia-datascience-grader)
#
# The images are built to start fast on a fresh machine:
#  - Most of the image is the Julia depot (compiled package caches, artifacts, package sources).
#    The final stages copy it in several balanced layers, so that Docker can download them in parallel
#    (it downloads three layers at a time; one big layer is a single slow stream).
#  - Everything Julia and Pluto set up the first time a notebook runs is done while building the image.

ARG TARGETARCH
ARG PLUTO_URL=https://github.com/ctessum/Pluto.jl
ARG PLUTO_REV=95df6823f8751073fb15fe5f2bbfb9ad487aa72a

# Julia compiles the cache of every package for the CPU of the machine that builds the image
# ("native") and rejects it, then recompiles everything at startup, on a machine with a different
# CPU (e.g. one that lacks a feature of the build machine). So build for a portable set of
# targets instead: these are Julia's own defaults for the system image. The variable has to be
# set while building and while running, because it is part of the cache key.
FROM julia:1.10 AS julia-amd64
ENV JULIA_CPU_TARGET="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
FROM julia:1.10 AS julia-arm64
ENV JULIA_CPU_TARGET="generic;cortex-a57;thunderx2t99;carmel,clone_all;apple-m1,base(3)"


# ---- The base system: Julia, the workspace user, and the directories.
FROM julia-${TARGETARCH} AS system

# Create workspace user (1001:1001).
ARG user=julia
ARG group=julia
ARG uid=1001
ARG gid=1001
RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/sh -m ${user} # <--- the '-m' creates a user home directory

USER julia
WORKDIR /home/julia

ENV PROJECT_DIR=/home/julia/project
ENV WORKSPACE_DIR=/home/julia/workspace
ENV DATA_DIR=${PROJECT_DIR}/data
RUN mkdir -p ${PROJECT_DIR}/src ${WORKSPACE_DIR}

ENV JULIA_NUM_THREADS=auto


# ---- The course packages (the notebook environment), precompiled.
FROM system AS project

COPY --chown=1001:1001 pl-julia-datascience-base/data ${DATA_DIR}
COPY --chown=1001:1001 pl-julia-datascience-base/Project.toml ${PROJECT_DIR}/
COPY --chown=1001:1001 pl-julia-datascience-base/UIUCDSQuestions.jl ${PROJECT_DIR}/src/

RUN julia --project=${PROJECT_DIR} -e 'using Pkg; Pkg.instantiate(); Pkg.precompile(); using PlutoUI, Plots'

# Moves the entries of the depot directories into a few balanced groups of the same size
# (/tmp/split/<name>/<n>), which the final stages copy as separate layers.
COPY --chmod=755 split.sh /usr/local/bin/split.sh


# ---- The bundled Pluto frontend. Pluto releases include it, but installing from a git commit does
# not, and the unbundled frontend loads hundreds of separate files (slow behind a proxy).
FROM node:22 AS pluto-frontend
ARG PLUTO_URL
ARG PLUTO_REV
RUN git clone ${PLUTO_URL} /pluto && cd /pluto && git checkout ${PLUTO_REV}
WORKDIR /pluto/frontend-bundler
RUN npm install && (npm run build || npm run build || npm run build)


# ---- The workspace: the course packages plus the Pluto server.
FROM project AS workspace-build

ENV JULIA_WORKER_TIMEOUT=3600
# The notebook worker process gets one thread (this is what limits memory use).
ENV JULIA_NUM_THREADS=1

# The Pluto server runs from its own environment that contains only Pluto, so it doesn't load the
# course packages itself. It uses the ctessum fork of Pluto (branch reduce-memory-use, pinned to a
# commit), which reduces the memory use of the server and of the notebook processes. The fork has
# the same version number as the Pluto release it is based on.
ARG PLUTO_URL
ARG PLUTO_REV
RUN JULIA_PKG_PRECOMPILE_AUTO=0 julia -e ' \
    using Pkg; \
    Pkg.activate("/home/julia/server"); \
    Pkg.add(url=ENV["PLUTO_URL"], rev=ENV["PLUTO_REV"])'

# Put the bundled frontend into the Pluto package before Pluto is precompiled (Pluto looks for it
# when it is loaded and remembers the result in its compile cache).
COPY --from=pluto-frontend --chown=1001:1001 /pluto/frontend-dist /tmp/frontend-dist
RUN pluto_dir=$(julia --project=/home/julia/server -e 'using Pkg; print(Pkg.dependencies()[Base.UUID("c3e4b0f8-55cb-11ea-2926-15256bba5781")].source)') \
    && mv /tmp/frontend-dist "$pluto_dir/frontend-dist" \
    && julia --project=/home/julia/server -e 'using Pkg; Pkg.precompile()'

# A system image with Pluto, its dependencies and the code that starting the server and serving the
# first page need, already compiled. Without it, a workspace host spends about 25 seconds compiling
# Pluto's code every time a workspace starts (it also uses less memory). The server is the only
# process that uses it. It is built for a generic CPU, which is plenty for a web server and needs
# much less memory to build. PackageCompiler is installed in a separate depot (/opt/pc) to keep it
# out of the image, and needs a C compiler.
COPY --chown=1001:1001 pl-julia-datascience-pluto-workspace/sysimage_workload.jl ${PROJECT_DIR}/
USER root
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev \
    && export JULIA_DEPOT_PATH=/opt/pc:/home/julia/.julia \
    && julia --project=/opt/pcenv -e 'using Pkg; Pkg.add("PackageCompiler")' \
    && julia --project=/opt/pcenv -e 'using PackageCompiler; create_sysimage(["Pluto"]; project="/home/julia/server", sysimage_path="/home/julia/server/pluto.so", precompile_execution_file="/home/julia/project/sysimage_workload.jl", cpu_target="generic")' \
    && chown julia:julia /home/julia/server/pluto.so \
    && apt-get clean \
    && rm -rf /opt/pc /opt/pcenv /var/lib/apt/lists/* /tmp/*
USER julia

COPY --chown=1001:1001 pl-julia-datascience-base/startup.jl ${PROJECT_DIR}/
COPY --chown=1001:1001 pl-julia-datascience-base/notebook.jl ${WORKSPACE_DIR}/
COPY --chown=1001:1001 --chmod=755 pl-julia-datascience-pluto-workspace/start.sh pl-julia-datascience-pluto-workspace/responder.jl pl-julia-datascience-pluto-workspace/warm.jl ${PROJECT_DIR}/

# Run a notebook once, so that what Pluto sets up the first time a notebook runs (the notebook
# environment and the compiled PlutoRunner) is part of the image instead of being redone in every
# new container (this takes about 20 seconds).
RUN julia --project=/home/julia/server ${PROJECT_DIR}/warm.jl

# Remove the debug information from the compiled files (about a fifth of their size). Julia does not
# use it: stack traces still show the file and line of the Julia source code. (Needs the tool
# "strip".) It runs after everything else that creates compiled files.
USER root
RUN apt-get update && apt-get install -y --no-install-recommends binutils \
    && find /home/julia/.julia/compiled /home/julia/server -name '*.so' -exec strip --strip-debug {} + \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*
USER julia

# Remove what is only needed while building, then split the depot into balanced groups.
RUN rm -rf /home/julia/.julia/clones /home/julia/.julia/logs /home/julia/.julia/pluto_notebooks /tmp/* \
    && mkdir -p /tmp/split \
    && /usr/local/bin/split.sh /home/julia/.julia/artifacts 3 /tmp/split/artifacts \
    && /usr/local/bin/split.sh /home/julia/.julia/compiled/v1.10 3 /tmp/split/compiled \
    && mv /home/julia/.julia/packages /tmp/split/packages \
    && mv /home/julia/server/pluto.so /tmp/split/pluto.so

FROM system AS workspace

ENV JULIA_WORKER_TIMEOUT=3600
ENV JULIA_NUM_THREADS=1

COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/artifacts/1/ /home/julia/.julia/artifacts/
COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/artifacts/2/ /home/julia/.julia/artifacts/
COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/artifacts/3/ /home/julia/.julia/artifacts/
COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/compiled/1/ /home/julia/.julia/compiled/v1.10/
COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/compiled/2/ /home/julia/.julia/compiled/v1.10/
COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/compiled/3/ /home/julia/.julia/compiled/v1.10/
COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/packages/ /home/julia/.julia/packages/
COPY --link --chown=1001:1001 --from=workspace-build /tmp/split/pluto.so /home/julia/server/pluto.so
# The rest (the project, the server environment, the registry, ...).
COPY --link --chown=1001:1001 --from=workspace-build /home/julia/ /home/julia/

EXPOSE 1234

CMD [ "/home/julia/project/start.sh", "--sysimage=/home/julia/server/pluto.so", "--project=/home/julia/server", "--color=no", "--heap-size-hint=300M", "/home/julia/project/startup.jl" ]


# ---- The autograder.
FROM project AS grader-build

# Remove the debug information from the compiled files (about a fifth of their size). Julia does not
# use it: stack traces still show the file and line of the Julia source code. (Needs the tool
# "strip".) It runs after everything else that creates compiled files.
USER root
RUN apt-get update && apt-get install -y --no-install-recommends binutils \
    && find /home/julia/.julia/compiled  -name '*.so' -exec strip --strip-debug {} + \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*
USER julia

RUN rm -rf /home/julia/.julia/clones /home/julia/.julia/logs /tmp/* \
    && mkdir -p /tmp/split \
    && /usr/local/bin/split.sh /home/julia/.julia/artifacts 3 /tmp/split/artifacts \
    && /usr/local/bin/split.sh /home/julia/.julia/compiled/v1.10 3 /tmp/split/compiled \
    && mv /home/julia/.julia/packages /tmp/split/packages

FROM system AS grader

# The grader needs to run as root.
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    uuid-runtime \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --link --chown=1001:1001 --from=grader-build /tmp/split/artifacts/1/ /home/julia/.julia/artifacts/
COPY --link --chown=1001:1001 --from=grader-build /tmp/split/artifacts/2/ /home/julia/.julia/artifacts/
COPY --link --chown=1001:1001 --from=grader-build /tmp/split/artifacts/3/ /home/julia/.julia/artifacts/
COPY --link --chown=1001:1001 --from=grader-build /tmp/split/compiled/1/ /home/julia/.julia/compiled/v1.10/
COPY --link --chown=1001:1001 --from=grader-build /tmp/split/compiled/2/ /home/julia/.julia/compiled/v1.10/
COPY --link --chown=1001:1001 --from=grader-build /tmp/split/compiled/3/ /home/julia/.julia/compiled/v1.10/
COPY --link --chown=1001:1001 --from=grader-build /tmp/split/packages/ /home/julia/.julia/packages/
COPY --link --chown=1001:1001 --from=grader-build /home/julia/ /home/julia/

COPY --chown=1001:1001 --chmod=+x pl-julia-datascience-grader/run.sh /

# Set an environment variable indicating that we're in the autograder.
ENV GRADER=TRUE
