### A Pluto.jl notebook ###
# v0.20.17

using Markdown
using InteractiveUtils

# ╔═╡ 8094d2de-2b98-11ec-168c-ad337353816e
begin
	# Deleting this cell may cause the notebook to stop working.
	if "PROJECT_DIR" ∈ keys(ENV)
		using Pkg; Pkg.activate(ENV["PROJECT_DIR"])
	end
	using PlutoUI, CSV, DataFrames
end

# ╔═╡ a61affdc-2a95-49b1-b1b0-68c3c1542126
PlutoUI.TableOfContents()

# ╔═╡ Cell order:
# ╠═8094d2de-2b98-11ec-168c-ad337353816e
# ╠═a61affdc-2a95-49b1-b1b0-68c3c1542126
