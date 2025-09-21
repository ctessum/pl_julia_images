using Pluto

session = Pluto.ServerSession()

session.options.compiler.heap_size_hint = "300M"

session.options.server.host = "0.0.0.0"
session.options.server.port=1234
session.options.server.launch_browser=false
#session.options.server.notebook="/home/julia/workspace/notebook.jl"
session.options.server.dismiss_update_notification=true

session.options.evaluation.workspace_use_distributed=false # Using distributed doubles the memory usage.

session.options.security.require_secret_for_access=false

notebook_path="/home/julia/workspace/notebook.jl"

Pluto.SessionActions.open(session, notebook_path; execution_allowed=false);
Pluto.run(session)
