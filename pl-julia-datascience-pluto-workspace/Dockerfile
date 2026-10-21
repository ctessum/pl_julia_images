ARG BASE_TAG=latest
FROM ctessum/pl-julia-datascience-base:${BASE_TAG}

ENV JULIA_WORKER_TIMEOUT=3600

# The notebook worker process gets one thread (this is what limits memory use).
ENV JULIA_NUM_THREADS=1

# The Pluto server runs from its own environment that contains only Pluto, so it doesn't
# load the course packages itself. It uses the ctessum fork of Pluto (branch
# reduce-memory-use, pinned to a commit), which reduces the memory use of the server and of
# the notebook processes. The fork has the same version number as the Pluto release in the
# project environment.
ARG PLUTO_URL=https://github.com/ctessum/Pluto.jl
ARG PLUTO_REV=95df6823f8751073fb15fe5f2bbfb9ad487aa72a
RUN julia -e ' \
    using Pkg; \
    Pkg.activate("/home/julia/server"); \
    Pkg.add(url=ENV["PLUTO_URL"], rev=ENV["PLUTO_REV"]); \
    Pkg.precompile()'

# Optional startup timing page (enabled by the environment variable PLUTO_STARTUP_DIAG).
COPY --chown=julia:julia --chmod=755 start.sh responder.jl /home/julia/project/

EXPOSE 1234

CMD [ "/home/julia/project/start.sh", "--project=/home/julia/server", "--color=no", "--heap-size-hint=300M", "/home/julia/project/startup.jl" ]
