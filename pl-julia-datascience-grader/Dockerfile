FROM ctessum/pl-julia-datascience-base:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    uuid-runtime \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


COPY run.sh /

# Add autograder user.
RUN useradd ag

# Set an environment variable indicating that we're in the autograder.
ENV GRADER TRUE

# Give autograder ownership of relevant files.
# Do some of the chowning in parallel. JL_DEPOT is the bulk of the work.
ARG chown_threads=4
USER 0:0
RUN find ${JL_DIR} -not -user ag -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ag && \
    find ${JL_DEPOT} -not -user ag -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ag && \
    find /data -not -user ag -print0 | xargs --no-run-if-empty -0 -P ${chown_threads} chown ag

RUN chmod +x /run.sh