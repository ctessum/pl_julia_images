# Startup timing for diagnosing slow starts: only active when start.sh runs in diagnostic mode
# (environment variable PLUTO_STARTUP_DIAG, set in info.json).
const startup_log = get(ENV, "PLUTO_STARTUP_LOG", nothing)
startup_stamp(msg) = startup_log === nothing || open(io -> println(io, Libc.strftime("%H:%M:%S", time()), " ", msg), startup_log, "a")
startup_stamp("startup.jl: Julia is running, loading Pluto")

using Pluto
startup_stamp("startup.jl: Pluto loaded")

session = Pluto.ServerSession()

# Heap size hint of the notebook process. A smaller hint makes the garbage collector run more
# often (less memory, but very slow for notebooks that hold a lot of data, e.g. training a
# model), so questions can override this with an environment variable in info.json.
session.options.compiler.heap_size_hint = get(ENV, "PLUTO_WORKER_HEAP_SIZE_HINT", "400M")

session.options.server.host = "0.0.0.0"
session.options.server.port=1234
session.options.server.launch_browser=false
#session.options.server.notebook="/home/julia/workspace/notebook.jl"
session.options.server.dismiss_update_notification=true

#session.options.evaluation.workspace_use_distributed=false # Using distributed doubles the memory usage.

session.options.security.require_secret_for_access=false

notebook_path="/home/julia/workspace/notebook.jl"

Pluto.SessionActions.open(session, notebook_path; execution_allowed=false);
startup_stamp("startup.jl: notebook opened")

if startup_log !== nothing
    # Stop the status page (responder.jl) that answers on port 1234 while starting, so Pluto can take over.
    touch("/tmp/stop_responder")
    for _ in 1:100
        isfile("/tmp/responder_closed") && break
        sleep(0.1)
    end
    startup_stamp("startup.jl: starting the Pluto server on port 1234 (this page is replaced by Pluto)")
end
Pluto.run(session)
