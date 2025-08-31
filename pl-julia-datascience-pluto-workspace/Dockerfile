FROM ctessum/pl-julia-datascience-base:latest

ENV JULIA_WORKER_TIMEOUT=3600

EXPOSE 1234

CMD [ "julia", "--project=/home/julia/project", "--color=no", "--heap-size-hint=300M", "/home/julia/project/startup.jl" ]