FROM julia:1.10

ENV JL_DIR=/jl
ENV JL_DEPOT=/jl_depot
RUN mkdir -p ${JL_DIR}
RUN mkdir -p ${JL_DEPOT}

ENV JULIA_NUM_THREADS=4
ENV JULIA_DEPOT_PATH=${JL_DEPOT}/.julia

# Copy files.
COPY data /data
COPY Project.toml ${JL_DIR}

ENV PRAIRIELEARN=TRUE

RUN julia --project=${JL_DIR} -E 'import Pkg; Pkg.instantiate()'