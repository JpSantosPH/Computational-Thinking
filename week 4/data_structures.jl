struct OneHot <: AbstractVector{Int}
	n::Int
	k::Int
end
Base.size(x::OneHot) = (x.n,)
Base.getindex(x::OneHot, i::Int) = Int(x.k == i)

struct OneCold <: AbstractVector{Int}
	n::Int
	k::Int
end
Base.size(x::OneCold) = (x.n,)
Base.getindex(x::OneCold, i::Int) = Int(x.k != i)

struct MultipicationTable <: AbstractMatrix{Real}
	oc::Vector{Real}
	or::Vector{Real}
end
Base.size(x::MultipicationTable) = (length(x.oc), length(x.or)+1)
Base.getindex(x::MultipicationTable, i::Int, j::Int) = x.oc[i] * if j==1 1 else x.or[j-1] end

struct Bernoulli # Bernoulli random variable or weigted coin toss
	p::Float64
end 
Base.rand(X::Bernoulli) = Int(rand() < X.p)

using Statistics

Statistics.mean(X::Bernoulli) = X.p
struct Binomial # Binomial random variable
	N::Int64
	p::Float64
end
Base.rand(X::Binomial) = sum(rand(Bernoulli(X.p)) for i in 1:X.N)
