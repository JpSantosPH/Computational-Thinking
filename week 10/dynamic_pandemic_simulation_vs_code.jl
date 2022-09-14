using Plots, LinearAlgebra

struct Coordinate
	x::Integer
	y::Integer
end
	possible_moves = [
		Coordinate( 1, 0), 
		Coordinate( 0, 1), 
		Coordinate(-1, 0), 
		Coordinate( 0,-1),
	]

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

	Base.rand(Coordinate, r::AbstractRange, N::Integer) = rand(Coordinate, r, r, N)

	function Base.:+(a::Coordinate, b::Coordinate)
		x = a.x + b.x
		y = a.y + b.y
		return Coordinate(x, y)
	end

	function make_tuple(c::Coordinate)
		return c.x, c.y
	end

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

abstract type AbstractInfection end
	function bernoulli(p::Number)
		rand() < p
	end

	struct CollisionInfectionRecovery <: AbstractInfection
		p_infection::Float64
		p_recovery::Float64
	end
	
	function successfully_infects(infection::AbstractInfection)
		return bernoulli(infection.p_infection)
	end

	function successfully_recovers(infection::AbstractInfection)
		return bernoulli(infection.p_recovery)
	end

abstract type AbstractAgent end
	@enum InfectionStatus S I R
		function color(s::InfectionStatus)
			if s == S
				"blue"
			elseif s == I
				"red"
			else
				"green"
			end
		end

	mutable struct Agent <: AbstractAgent
		position::Coordinate
		status::InfectionStatus
		num_infected::Integer
	end
		function initialize(N::Number, L::Number)
			coordinates = rand(Coordinate, -L:L, N)
			agents = [Agent(coordinates[i], S, 0) for i ∈ 1:N]
			set_status!(rand(agents), I)
			return agents
		end

		function simulation(N::Number, L::Number, infection::AbstractInfection, k::Number)
			agents = initialize(N, L)
		
			sᵢ, iᵢ, rᵢ = SIR_count(agents)
			susceptible = [sᵢ]
			infected = [iᵢ]
			recovered = [rᵢ]
			
			simulations = [deepcopy(agents)]
			
			for i in 1:k
				sweep!(agents, L, infection)
				sᵢ, iᵢ, rᵢ = SIR_count(agents)
				push!(susceptible, sᵢ)
				push!(infected, iᵢ)
				push!(recovered, rᵢ)
		
				simulation_state = deepcopy(agents)
				push!(simulations, simulation_state)
			end
			
			return susceptible, infected, recovered, simulations
		end

	mutable struct SocialAgent <: AbstractAgent
		position::Coordinate
		status::InfectionStatus
		num_infected::Integer
		social_score::Number
	end
		possible_social_scores = collect(LinRange(0.1, 0.5, 10))

		social_score(agent::SocialAgent) = agent.social_score

		function update_social_score!(agent::SocialAgent, new_social_score)
			agent.social_score = new_social_score
		end

		function initialize_social(N::Number, L::Number)
			coordinates = rand(Coordinate, -L:L, N)
			agents = [SocialAgent(coordinates[i], S, 0, rand(possible_social_scores)) for i ∈ 1:N]
			set_status!(rand(agents), I)
			return agents
		end

		function interacted(agent::SocialAgent, source::SocialAgent)
			p = agent.social_score + source.social_score
			return bernoulli(p)
		end

		function interact!(agent::SocialAgent, source::SocialAgent, infection::CollisionInfectionRecovery)
			if in_contact(agent, source)
				if status(agent) == S && status(source) == I
					if interacted(agent, source)
						if successfully_infects(infection)
							set_status!(agent, I)
							update_num_infected!(source)
						end
					end
				elseif status(agent) == I
					if successfully_recovers(infection)	
						set_status!(agent, R)
					end
				end
			end
		end

		function lockdown!(agents::Vector{SocialAgent}, n::Number)
			for i in eachindex(agents)
			agent_social_score = social_score(agents[i])
			new_social_score = n * agent_social_score
			update_social_score!(agents[i], new_social_score)
			end
		end

	position(agent::AbstractAgent) = agent.position
	color(agent::AbstractAgent) = color(agent.status)
	status(agent::AbstractAgent) = agent.status
	num_infected(agent::AbstractAgent) = agent.num_infected

	function Base.:-(agents::Vector, source::AbstractAgent)
		return setdiff(agents, [source])
	end

	function set_status!(agent::AbstractAgent, new_status::InfectionStatus)
		agent.status = new_status
	end

	function update_num_infected!(source::AbstractAgent)
		source.num_infected += 1
	end

	function update_position!(agent::AbstractAgent, new_position::Coordinate)
		agent.position = new_position
	end

	function in_contact(agent::AbstractAgent, source::AbstractAgent)
		return agent.position == source.position
	end

	function visualize(agents::Vector, L::Number)
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

	function interact!(agent::AbstractAgent, source::AbstractAgent, infection::CollisionInfectionRecovery)
		if in_contact(agent, source)
			if status(agent) == S && status(source) == I && successfully_infects(infection)
				set_status!(agent, I)
				update_num_infected!(source)
			elseif status(agent) == I && successfully_recovers(infection)
				set_status!(agent, R)
			end
		end
	end

	function interact!(agents::Vector, source::AbstractAgent, infection::CollisionInfectionRecovery)
		for i in eachindex(agents)
			interact!(agents[i], source, infection)
		end
	end
	
	function random_walk!(agent::AbstractAgent; L=Inf, n=1)
		position_agent = position(agent)
		
		for i in 1:n
		position_agent = collide_boundary(position_agent + rand(possible_moves), L)
		end
	
		update_position!(agent, position_agent)
		return agent
	end

	function step!(agents::Vector, L::Number, infection::AbstractInfection)
		source = rand(agents)
		random_walk!(source, L=L)
		
		other_agents = agents - source
		interact!(other_agents, source, infection)
	return agents
	end

	function sweep!(agents::Vector, L::Number, infection::AbstractInfection)
		for i in eachindex(agents)
			step!(agents, L, infection)
		end
	end

	function k_sweeps!(agents::Vector, L::Number, infection::AbstractInfection, k::Number)
		for i in 1:k
			sweep!(agents, L, infection)
		end
	end

	function SIR_count(agents::Vector)
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
	
		return susceptible, infected, recovered
	end


	let
		N = 50
		L = 40
		infection = CollisionInfectionRecovery(0.20, 0.02)
		social_agents = initialize_social(N, L)
		Ss, Is, Rs = [], [], []
		
		Tmax = 200
		
		@gif for t in 1:Tmax
			if t == 100
				lockdown!(social_agents, 0.25)
			end
			
			for i in 1:50N
				step!(social_agents, L, infection)
			end
	
			S, I, R = SIR_count(social_agents)
			push!(Ss, S)
			push!(Is, I)
			push!(Rs, R)
			
			left = visualize(social_agents, L)
	
			right = plot(xlim=(1,Tmax), ylim=(1,N))
			plot!(right, 1:t, Ss, color="blue", label="Susceptible")
			plot!(right, 1:t, Is, color="red", label="Infected")
			plot!(right, 1:t, Rs, color="green", label="Recovered")
		
			plot(left, right, size=(600,300))
		end
	end

	social_agents = initialize_social(50, 40)

	before = social_score.(social_agents)

	lockdown!(social_agents, 0.25)

	after = social_score.(social_agents)

	hcat(before, after)