# Julia compiles the cache of every package for the CPU of the machine that builds the image
# ("native") and rejects it, then recompiles everything at startup, on a machine with a different
# CPU (e.g. one that lacks a feature of the build machine). So build for a portable set of
# targets instead: these are Julia's own defaults for the system image. The variable has to be
# set while building and while running, because it is part of the cache key.
ARG TARGETARCH
FROM julia:1.10 AS julia-amd64
ENV JULIA_CPU_TARGET="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
FROM julia:1.10 AS julia-arm64
ENV JULIA_CPU_TARGET="generic;cortex-a57;thunderx2t99;carmel,clone_all;apple-m1,base(3)"

FROM julia-${TARGETARCH}

# Create workspace user (1001:1001).
ARG user=julia
ARG group=julia
ARG uid=1001
ARG gid=1001
RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/sh -m ${user} # <--- the '-m' creates a user home directory

# Switch to user
USER ${uid}:${gid}
USER julia

WORKDIR /home/julia

ENV PROJECT_DIR=/home/julia/project
ENV WORKSPACE_DIR=/home/julia/workspace
ENV DATA_DIR=${PROJECT_DIR}/data
RUN mkdir -p ${PROJECT_DIR}
RUN mkdir -p ${PROJECT_DIR}/src
RUN mkdir -p ${WORKSPACE_DIR}

ENV JULIA_NUM_THREADS=auto

# Copy files.
COPY --chown=julia:julia data ${DATA_DIR}
COPY --chown=julia:julia Project.toml ${PROJECT_DIR}/
COPY --chown=julia:julia warmup.jl ${PROJECT_DIR}/
COPY --chown=julia:julia startup.jl ${PROJECT_DIR}/
COPY --chown=julia:julia notebook.jl ${WORKSPACE_DIR}/
COPY --chown=julia:julia UIUCDSQuestions.jl ${PROJECT_DIR}/src/

RUN julia --project=${PROJECT_DIR} ${PROJECT_DIR}/warmup.jl