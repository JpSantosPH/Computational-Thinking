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

struct MultipicationTable <: AbstractMatrix{Int}

end

Base.size(x::MultipicationTable) =
Base.getindex(x::MultipicationTable, i::Int, j::Int) = 