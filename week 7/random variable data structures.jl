using Statistics
using LinearAlgebra
using Plots

abstract type RandomVariable
end
    Statistics.std(X::RandomVariable) =  sqrt(var(X))
    Plots.histogram(X::RandomVariable; kw...) = histogram([rand(X) for i in 1:10^6], norm=true, leg=false, alpha=0.5, size=(500, 300), kw...)


struct SumOfTwoRandomVariables <: RandomVariable
	X₁::RandomVariable
	X₂::RandomVariable
end
    Base.:+(X1::RandomVariable, X2::RandomVariable) = SumOfTwoRandomVariables(X1, X2)
    Statistics.mean(S::SumOfTwoRandomVariables) = mean(S.X₁) + mean(S.X₂)
    Statistics.var(S::SumOfTwoRandomVariables) = var(S.X₁) + var(S.X₂)
    Base.rand(S::SumOfTwoRandomVariables) = rand(S.X₁) + rand(S.X₂)

abstract type DiscreteRandomVariable <: RandomVariable
end

abstract type ContinuousRandomVariable <: RandomVariable
end

struct Gaussian <: ContinuousRandomVariable
    μ
    σ²
end
    Gaussian() = Gaussian(0.0, 1.0)
    Statistics.mean(X::Gaussian) = X.μ
    Statistics.var(X::Gaussian) = X.σ²
    Base.:+(X::Gaussian, Y::Gaussian) = Gaussian(X.μ + Y.μ, X.σ² + Y.σ²)
    pdf(X::Gaussian) = x -> exp(-0.5 * ( (x - X.μ)^2 / X.σ²) ) / √(2π * X.σ²)
    Base.rand(X::Gaussian) = X.μ + √(X.σ²) * randn()

struct Bernoulli <: DiscreteRandomVariable
	p::Real
end

    Statistics.mean(X::Bernoulli) = X.p
    Statistics.var(X::Bernoulli) = X.p * (1 - X.p)
    Base.rand(X::Bernoulli) = Int(rand() < X.p)

Bernoulli(0.5)
struct Binomial <: DiscreteRandomVariable
    n::Integer
    p::Real
end
    function Binomial(n::Integer, p::Real)
        if n >= 1 && (0 <= p <= 1)
            return n, p
        elseif n <= 0 
            error("n must be a positive integer")
        elseif 0 > p > 1
            error("p must b between 0 and 1")
        end
    end
Statistics.mean(X::Binomial) = X.n * X.p
Binomial(2, 1)

struct ChiSquared <: ContinuousRandomVariable
    f::Integer
end
    Base.rand(X::ChiSquared) = sum(rand(Gaussian())^2 for i in 1:X.f)
    Statistics.mean(X::ChiSquared) = X.f
    Statistics.var(X::ChiSquared) = 2X.f

