# Runs while the Pluto server system image is built (see the Dockerfile): everything this does is
# compiled into the system image, so that the server starts and answers its first requests without
# compiling Pluto's code (which takes about 25 seconds on a workspace host).
# It does what a workspace does: start the server with a notebook open, and what a browser does:
# load the page, open a WebSocket, and receive the notebook state.
using Pluto
const HTTP = Pluto.HTTP

dir = mktempdir()
path = joinpath(dir, "notebook.jl")
write(path, """
### A Pluto.jl notebook ###
# v0.20.17

using Markdown
using InteractiveUtils

# ╔═╡ 8094d2de-2b98-11ec-168c-ad337353816e
begin
	if "PROJECT_DIR" ∈ keys(ENV)
		using Pkg; Pkg.activate(ENV["PROJECT_DIR"])
	end
	using PlutoUI, CSV, DataFrames
end

# ╔═╡ 2e6f1f0d-0b5e-4a09-8e0f-7d1f3b1c2a11
md\"\"\"
# Title

Some *text* with math \$x^2\$.
\"\"\"

# ╔═╡ a61affdc-2a95-49b1-b1b0-68c3c1542126
function f(x::Real)
	y = x^2 + 1
	return y / 2
end

# ╔═╡ 3c1b6c9e-8a2d-4f0e-9d3a-5b7e4f6a8c21
f(2)

# ╔═╡ Cell order:
# ╠═8094d2de-2b98-11ec-168c-ad337353816e
# ╠═2e6f1f0d-0b5e-4a09-8e0f-7d1f3b1c2a11
# ╠═a61affdc-2a95-49b1-b1b0-68c3c1542126
# ╠═3c1b6c9e-8a2d-4f0e-9d3a-5b7e4f6a8c21
""")

port = 13999
session = Pluto.ServerSession(;
    options=Pluto.Configuration.from_flat_kwargs(;
        host="127.0.0.1",
        port,
        launch_browser=false,
        require_secret_for_access=false,
        dismiss_update_notification=true,
        disable_writing_notebook_files=true,
    )
)

# Same as startup.jl (without code execution, which needs the course packages).
notebook = Pluto.SessionActions.open(session, path; execution_allowed=false)
server = Pluto.run!(session)

try
    base = "http://127.0.0.1:$port"
    for suffix in ("", "ping", "edit?id=$(notebook.notebook_id)", "this-route-does-not-exist")
        HTTP.get("$base/$suffix"; status_exception=false)
    end

    # The browser connects, asks for the notebook state, and pings.
    HTTP.WebSockets.open("ws://127.0.0.1:$port/") do ws
        # Never block the build: close the connection if the replies take too long.
        watchdog = Timer(30) do _
            close(ws)
        end
        for (type, body) in (("connect", Dict()), ("reset_shared_state", Dict()), ("ping", Dict()))
            HTTP.WebSockets.send(ws, Pluto.pack(Dict(
                "type" => type,
                "client_id" => "workload_client",
                "request_id" => "workload_request_$type",
                "notebook_id" => string(notebook.notebook_id),
                "body" => body,
            )))
        end
        # The replies: connect, the notebook state, and ping.
        for _ in 1:3
            msg = HTTP.WebSockets.receive(ws)
            Pluto.unpack(msg)
        end
        close(watchdog)
    end
finally
    close(server)
    rm(dir; recursive=true, force=true)
end
