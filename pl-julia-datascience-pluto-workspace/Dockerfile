ARG BASE_TAG=latest

# Pluto is installed from the ctessum fork (branch reduce-memory-use, pinned to a commit), which
# reduces the memory use of the server and of the notebook processes.
ARG PLUTO_URL=https://github.com/ctessum/Pluto.jl
ARG PLUTO_REV=95df6823f8751073fb15fe5f2bbfb9ad487aa72a

# Build the bundled frontend. Pluto releases include it, but installing from a git commit does
# not, and the unbundled frontend loads hundreds of separate files (slow behind a proxy).
FROM node:22 AS pluto-frontend
ARG PLUTO_URL
ARG PLUTO_REV
RUN git clone ${PLUTO_URL} /pluto && cd /pluto && git checkout ${PLUTO_REV}
WORKDIR /pluto/frontend-bundler
RUN npm install && (npm run build || npm run build || npm run build)

FROM ctessum/pl-julia-datascience-base:${BASE_TAG}

ENV JULIA_WORKER_TIMEOUT=3600

# The notebook worker process gets one thread (this is what limits memory use).
ENV JULIA_NUM_THREADS=1

# The Pluto server runs from its own environment that contains only Pluto, so it doesn't
# load the course packages itself. The fork has the same version number as the Pluto release in
# the project environment.
ARG PLUTO_URL
ARG PLUTO_REV
RUN JULIA_PKG_PRECOMPILE_AUTO=0 julia -e ' \
    using Pkg; \
    Pkg.activate("/home/julia/server"); \
    Pkg.add(url=ENV["PLUTO_URL"], rev=ENV["PLUTO_REV"])'

# Put the bundled frontend into the Pluto package before Pluto is precompiled (Pluto looks for it
# when it is loaded and remembers the result in its compile cache).
COPY --from=pluto-frontend --chown=julia:julia /pluto/frontend-dist /tmp/frontend-dist
RUN pluto_dir=$(julia --project=/home/julia/server -e 'using Pkg; print(Pkg.dependencies()[Base.UUID("c3e4b0f8-55cb-11ea-2926-15256bba5781")].source)') \
    && mv /tmp/frontend-dist "$pluto_dir/frontend-dist" \
    && julia --project=/home/julia/server -e 'using Pkg; Pkg.precompile()'

# Optional startup timing page (enabled by the environment variable PLUTO_STARTUP_DIAG).
COPY --chown=julia:julia --chmod=755 start.sh responder.jl /home/julia/project/

EXPOSE 1234

CMD [ "/home/julia/project/start.sh", "--project=/home/julia/server", "--color=no", "--heap-size-hint=300M", "/home/julia/project/startup.jl" ]
