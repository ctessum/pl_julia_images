@info "running startup"

using Pluto

server_options = Pluto.Configuration.ServerOptions(; host="0.0.0.0", 
                        port=1234, 
                        launch_browser=false,
                        #notebook="/home/julia/notebook.jl",
                        notebook="precompile_notebook.jl",
                        dismiss_update_notification=true,
                    )
eval_options = Pluto.Configuration.EvaluationOptions(;
    workspace_use_distributed=false, # Using distributed doubles the memory usage.
)
security_options = Pluto.Configuration.SecurityOptions(; require_secret_for_access=false)
t = @async Pluto.run(Pluto.Configuration.Options(; server=server_options, security=security_options, evaluation=eval_options))


sleep(60)
@info "throwing interrupt"
@async Base.throwto(t, InterruptException())
sleep(2)
@info "done"