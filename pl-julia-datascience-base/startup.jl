using Pluto

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
Pluto.run(session)
