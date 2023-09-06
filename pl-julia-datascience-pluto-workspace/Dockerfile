FROM ctessum/pl-julia-datascience-base:latest

# Add pluto startup script.
COPY startup.jl ${JL_DIR} 

# Create workspace user (1001:1001).
ARG user=julia
ARG group=julia
ARG uid=1001
ARG gid=1001
RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/sh -m ${user} # <--- the '-m' creates a user home directory

# Make the user the owner of necessary directories.
# Do some of the chowning in parallel. JL_DEPOT is the bulk of the work.
ARG chown_threads=4
USER 0:0
RUN find ${JL_DIR} -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid} && \
    find ${JL_DEPOT} -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid} && \
    find /data -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid} && \
    find /home/julia -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid}

# Switch to user
USER ${uid}:${gid}
USER julia

WORKDIR /home/julia
VOLUME /home/julia

ENV JULIA_WORKER_TIMEOUT=3600

EXPOSE 1234

# Precompile startup package
COPY --chown=${uid}:${gid} Startup/ ${JL_DIR}/Startup/
USER 0:0
RUN julia --project=${JL_DIR} -E "import Pkg; Pkg.develop(path=\"${JL_DIR}/Startup\"); using Startup"

# Fix permissions again
USER 0:0
RUN find ${JL_DIR} -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid} && \
    find ${JL_DEPOT} -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid} && \
    find /data -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid} && \
    find /home/julia -not \( -user ${uid} -group ${gid} \) -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ${uid}:${gid}

CMD [ "julia", "--project=/jl", "--color=no", "--heap-size-hint=1G", "/jl/startup.jl" ]