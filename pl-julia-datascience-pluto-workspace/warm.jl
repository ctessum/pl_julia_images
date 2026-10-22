# Runs a notebook once while building the image, so that what Pluto sets up the first time a
# notebook runs (the notebook environment, the compiled PlutoRunner) is part of the image.
# Run with the Pluto server environment: julia --project=/home/julia/server warm.jl
using Pluto

path = joinpath(mktempdir(), "warm.jl")
write(path, """
### A Pluto.jl notebook ###
# v0.20.17

using Markdown
using InteractiveUtils

# ╔═╡ 8094d2de-2b98-11ec-168c-ad337353816e
md"Hello"

# ╔═╡ a61affdc-2a95-49b1-b1b0-68c3c1542126
1 + 1

# ╔═╡ Cell order:
# ╠═8094d2de-2b98-11ec-168c-ad337353816e
# ╠═a61affdc-2a95-49b1-b1b0-68c3c1542126
""")

session = Pluto.ServerSession(;
    options=Pluto.Configuration.from_flat_kwargs(
        launch_browser=false,
        require_secret_for_access=false,
        dismiss_update_notification=true,
        disable_writing_notebook_files=true,
    )
)
notebook = Pluto.SessionActions.open(session, path; run_async=false, execution_allowed=true)
errored = count(c -> c.errored, notebook.cells)
Pluto.SessionActions.shutdown(session, notebook)
errored == 0 || error("The warm-up notebook failed")
@info "Warm-up done"
