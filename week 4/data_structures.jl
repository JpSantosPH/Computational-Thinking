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
