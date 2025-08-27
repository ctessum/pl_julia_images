FROM ctessum/pl-julia-datascience-base:latest

# The grader needs to run as root.
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    uuid-runtime \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


COPY --chown=julia:julia --chmod=+x run.sh /

# Set an environment variable indicating that we're in the autograder.
ENV GRADER=TRUE
