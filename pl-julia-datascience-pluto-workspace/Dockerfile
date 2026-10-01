ARG BASE_TAG=latest
FROM ctessum/pl-julia-datascience-base:${BASE_TAG}

ENV JULIA_WORKER_TIMEOUT=3600

# The notebook worker process gets one thread (this is what limits memory use).
ENV JULIA_NUM_THREADS=1

# The Pluto server runs from its own environment that contains only Pluto, at the same
# version as the project environment, so it doesn't load the course packages itself.
RUN julia --project=${PROJECT_DIR} -e ' \
    using Pkg; \
    v = Pkg.dependencies()[Base.UUID("c3e4b0f8-55cb-11ea-2926-15256bba5781")].version; \
    Pkg.activate("/home/julia/server"); \
    Pkg.add(name="Pluto", version=string(v)); \
    Pkg.precompile()'

EXPOSE 1234

CMD [ "julia", "--project=/home/julia/server", "--color=no", "--heap-size-hint=500M", "--compile=min", "-O0", "--gcthreads=1,0", "/home/julia/project/startup.jl" ]
