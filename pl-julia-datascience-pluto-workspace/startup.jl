using Startup # Startup module with precompiled Pluto.run()
using Pluto

server_options = Pluto.Configuration.ServerOptions(; host="0.0.0.0", 
                        port=1234, 
                        launch_browser=false,
                        notebook="/home/julia/notebook.jl",
                        dismiss_update_notification=true,
                    )
eval_options = Pluto.Configuration.EvaluationOptions(;
    workspace_use_distributed_stdlib=false, # Using distributed doubles the memory usage.
    workspace_use_distributed=true, # Using distributed doubles the memory usage.
)
security_options = Pluto.Configuration.SecurityOptions(; require_secret_for_access=false)
Pluto.run(Pluto.Configuration.Options(; server=server_options, security=security_options, evaluation=eval_options))