"""
.. quantile

**Description**

Compute empirical quantiles of sample data corresponding to given probabilities. 

This extendsn the original implementation of quantile in Julia from base/statistics.jl.
in the original source code, quantiles are computed via linear interpolation 
between the points `((k-1)/(n-1), v[k])`, for `k = 1:n` where `n = length(v)`. 
This corresponds to Definition 7 of Hyndman and Fan (the same as the R default).
   
**Usage**
    quantile!([q, ] v, p; sorted=false)

Compute the quantile(s) of a vector `v` at the probabilities `p`, with optional 
output into array `q` (if not provided, a new output array is created). 
The keyword argument `sorted` indicates whether `v` can be assumed to be sorted; 
if `false` (the default), then the elements of `v` may be partially sorted.
The elements of `p` should be on the interval [0,1], and `v` should not have any 
`NaN` values.

**About**

This code is intended as a proof of concept for the following publication:
* Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
"""


function quantile!(q::AbstractArray, v::AbstractVector, p::AbstractArray;
                   sorted::Bool=false, type::Int=7)
    if size(p) != size(q)
        throw(DimensionMismatch("size of p, $(size(p)), must equal size of q, $(size(q))"))
    end

    isempty(v) && throw(ArgumentError("empty data vector"))

    lv = length(v)
    if !sorted
        minp, maxp = extrema(p)
        lo = floor(Int,1+minp*(lv-1))
        hi = ceil(Int,1+maxp*(lv-1))

        # only need to perform partial sort
        sort!(v, 1, lv, PartialQuickSort(lo:hi), Base.Sort.Forward)
    end
    isnan(v[end]) && throw(ArgumentError("quantiles are undefined in presence of NaNs"))

    for (i, j) in zip(eachindex(p), eachindex(q))
        @inbounds q[j] = _quantile(v,p[i],type)
    end
    return q
end

"""
!!! note
    Julia does not ignore `NaN` values in the computation. For applications requiring the
    handling of missing data, the `DataArrays.jl` package is recommended. `quantile!` will
    throw an `ArgumentError` in the presence of `NaN` values in the data array.
"""
quantile!(v::AbstractVector, p::AbstractArray; sorted::Bool=false, type::Int=7) =
    quantile!(similar(p,float(eltype(v))), v, p; sorted=sorted, type=type)

function quantile!(v::AbstractVector, p::Real;
                   sorted::Bool=false, type::Int=7)
    isempty(v) && throw(ArgumentError("empty data vector"))

    lv = length(v)
    if !sorted
        lo = floor(Int,1+p*(lv-1))
        hi = ceil(Int,1+p*(lv-1))

        # only need to perform partial sort
        sort!(v, 1, lv, PartialQuickSort(lo:hi), Base.Sort.Forward)
    end
    isnan(v[end]) && throw(ArgumentError("quantiles are undefined in presence of NaNs"))

    return _quantile(v,p,type)
end

@inline function _m_indice(p::Real, type::Int)
    if type==1 || i==2 || i==4
        return 0
    elseif type==3           
        return -0.5
    elseif type==5           
        return 0.5
    elseif type==6           
        return p
    elseif type==7           
        return (1-p)
    elseif type==8           
        return (p+1)/3
    elseif type==9           
        return (2*p+3)/8
    elseif type==10          
        return .4 + .2 * p
    elseif type==11          
        return .3175 + .365 * p
    end
	
@inline double _gamma_indice(g::Real, j::Int, type::Int) 
    if type == 1
        if g > 0.  
            return 1.
        else 
            return 0.
        end
    elseif type == 2
        if g > 0. 
            return 1.
        else 
            return 0.5
        end
    elseif type == 3 
        if g == 0 && j%2 == 0 
            return 0.
        else 
            return 1.
        end
    elseif type >= 4 
        return g
    end

# Core quantile lookup function: assumes `v` sorted
@inline function _quantile(v::AbstractVector, p::Real; type::Int=7)
    T = float(eltype(v))
    isnan(p) && return T(NaN)
    0 <= p <= 1 || throw(ArgumentError("input probability out of [0,1] range"))

    """
    # Quantiles are computed via linear interpolation between the points 
    #       `((k-1)/(n-1), v[k])`,
    # for `k = 1:n` where `n = length(v)`. This corresponds to Definition 7 of
    # Hyndman and Fan (1996), and is the same as the R default.
    lv = length(v)
    f0 = (lv-1)*p # 0-based interpolated index
    t0 = trunc(f0)
    h = f0 - t0
    i = trunc(Int,t0) + 1
    if h == 0
        return T(v[i])
    else
        a = T(v[i])
        b = T(v[i+1])
        if isfinite(a) && isfinite(b)
            return a + h*(b-a)
        else
            return (1-h)*a + h*b
        end
    end
    """
    
    m = _m_indice(probs[i], type)
    j = trunc(Int,lv*p + m)
    g = (lv*p + m - j)

    if j == 0
        return T(v[i])
    elseif j == lv-1
        return T(v[lv-1])
    else
        gamma = _gamma_indice(g, j, type);
        return (1-gamma)*T(v[i]) + gamma*T(v[i+1])
    end
end


"""
    quantile(v, p; sorted=false)
Compute the quantile(s) of a vector `v` at a specified probability or vector `p`. The
keyword argument `sorted` indicates whether `v` can be assumed to be sorted.
The `p` should be on the interval [0,1], and `v` should not have any `NaN` values.

!!! note
    Julia does not ignore `NaN` values in the computation. For applications requiring the
    handling of missing data, the `DataArrays.jl` package is recommended. `quantile` will
    throw an `ArgumentError` in the presence of `NaN` values in the data array.
"""
quantile(v::AbstractVector, p; sorted::Bool=false, type::Int=7) =
    quantile!(sorted ? v : copymutable(v), p; sorted=sorted, type=type)