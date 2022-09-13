using Plots

struct Coordinate
	x::Integer
	y::Integer
end

@enum InfectionStatus S I R

mutable struct Agent
	position::Coordinate
	status::InfectionStatus
	num_infected::Integer
end

abstract type AbstractInfection end

struct CollisionInfectionRecovery <: AbstractInfection
	p_infection::Float64
	p_recovery::Float64
end

function bernoulli(p::Number)
	rand() < p
end

function Base.rand(Coordinate, r₁::AbstractRange, r₂::AbstractRange, N::Integer)
    n = abs(N)
    l₁ = length(r₁)
    l₂ = length(r₂)

	coordinates = Coordinate[]
	for i in 1:N
		x = rand(r₁)
		y = rand(r₂)
		push!(coordinates, Coordinate(x, y))
	end
	    
	return coordinates
end

function make_tuple(c::Coordinate)
	return c.x, c.y
end

function Base.:+(a::Coordinate, b::Coordinate)
	x = a.x + b.x
	y = a.y + b.y
	return Coordinate(x, y)
end

function Base.:-(agents::Vector{Agent}, source::Agent)
	return setdiff(agents, [source])
end

possible_moves = [
    Coordinate( 1, 0), 
    Coordinate( 0, 1), 
    Coordinate(-1, 0), 
    Coordinate( 0,-1),
    ]

Base.rand(Coordinate, r::AbstractRange, N::Integer) = rand(Coordinate, r, r, N)

function trajectory(w::Coordinate, n::Int)
	random_moves = rand(possible_moves, n)
	trajectory = accumulate(+, random_moves, init=w)
	
	return trajectory
end

function plot_trajectory!(p::Plots.Plot, trajectory::Vector; kwargs...)
	plot!(p, make_tuple.(trajectory); 
		label=nothing, 
		linewidth=2, 
		color = "red",
		linealpha=LinRange(1.0, 0.2, length(trajectory)),
		kwargs...)
end

function collide_boundary(c::Coordinate, L::Number)
	x = c.x
	y = c.y
	
	in_x = -L ≤ x ≤ L
	in_y = -L ≤ y ≤ L

	if !in_x
		x = x ÷ abs(x) * L
	end
	
	if !in_y
		y = y ÷ abs(y) * L
	end
	
	return Coordinate(x, y)
end

function trajectory(c::Coordinate, n::Int, L::Number)

	positions = [c]
	
	for i in 1:n
		step = rand(possible_moves)
		new_position = collide_boundary(positions[i] + step, L)
		push!(positions, new_position)
	end
	
	return positions
end

function set_status!(agent::Agent, new_status::InfectionStatus)
	agent.status = new_status
end

function initialize(N::Number, L::Number)
	coordinates = rand(Coordinate, -L:L, N)
	agents = [Agent(coordinates[i], S, 0) for i ∈ 1:N]
	set_status!(rand(agents), I)
	return agents
end

function color(s::InfectionStatus)
    if s == S
	    "blue"
    elseif s == I
	    "red"
    else
	    "green"
    end
end

position(a::Agent) = a.position
color(a::Agent) = color(a.status)
status(a::Agent) = a.status

function visualize(agents::Vector{Agent}, L::Number)
	colors = color.(agents)
	positions = make_tuple.(position.(agents))
    x = Int[]
    y = Int[]
    for i in eachindex(positions)
        xᵢ, yᵢ = positions[i]
        push!(x, xᵢ)
        push!(y, yᵢ)
	end
	p = scatter(
        x,
        y,
        color = colors,
		ratio = 1,
		xlim = (-L*11/10, L*11/10),
		ylim = (-L*11/10, L*11/10),
		alpha = 0.5,
        legend = false
    )
		
	return p
end

function in_contact(agent::Agent, source::Agent)
	return agent.position == source.position
end

function successfully_infects(infection::AbstractInfection)
	return bernoulli(infection.p_infection)
end

function successfully_recovers(infection::AbstractInfection)
	return bernoulli(infection.p_recovery)
end

function update_num_infected!(source::Agent)
	source.num_infected += 1
end

function update_position!(agent::Agent, new_position::Coordinate)
	agent.position = new_position
end

function interact!(agent::Agent, source::Agent, infection::CollisionInfectionRecovery)
	if in_contact(agent, source)
		if status(agent) == S && status(source) == I && successfully_infects(infection)
			set_status!(agent, I)
			update_num_infected!(source)
		elseif status(agent) == I && successfully_recovers(infection)
			set_status!(agent, R)
		end
	end
end

function interact!(agents::Vector{Agent}, source::Agent, infection::CollisionInfectionRecovery)

	for i in eachindex(agents)
		interact!(agents[i], source, infection)
	end

end

function random_walk!(agent::Agent; L=Inf, n=1)
	
	position_agent = position(agent)
	
	for i in 1:n
	position_agent = collide_boundary(position_agent + rand(possible_moves), L)
	end

	update_position!(agent, position_agent)
	return agent
end
update_num_infected!
function step!(agents::Vector{Agent}, L::Number, infection::AbstractInfection)
	source = rand(agents)
	random_walk!(source, L=L)
	
	other_agents = agents - source
	interact!(other_agents, source, infection)
	
return agents
end

function sweep!(agents::Vector{Agent}, L::Number, infection::AbstractInfection)
	
    for i in eachindex(agents)
        step!(agents, L, infection)
    end
end

function k_sweeps!(agents::Vector{Agent}, L::Number, infection::AbstractInfection, k::Number)

    for i in 1:k
        sweep!(agents, L, infection)
    end
end

function count_SIR(agents::Vector{Agent})
	susceptible = 0
	infected = 0
	recovered = 0

	for i in eachindex(agents)
		agent_status = status(agents[i])
		if agent_status == S
			susceptible += 1
		elseif agent_status == I
			infected += 1
		elseif agent_status == R
			recovered += 1
		end
	end

	return (susceptible, infected, recovered)
end	

