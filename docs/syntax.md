**<a name="Syntax"></a>Syntax**


* _Python_ code

    
        >>> q = quantile(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1))
        
    Arguments
    ---------
    x : numpy.array
        input vector data; 2D arrays are also accepted.
    na_rm : bool
        default: `na_rm=False`.
    type : int
        default: `type=7`.
    method : str
        string defining the estimation method
    limit: list,tuple
    
    Returns
    -------
    
    Documentation of scipy.stats.mstats.mquantiles
    
    Samples quantile are defined by 
        Q(p) = (1-gamma)*x[j] + gamma*x[j+1], 
    where x[j] is the j-th order statistic, and gamma is a function of j = floor(n*p + m), 
    m = alphap + p*(1 - alphap - betap) and g = n*p + m - j.
    
    Reinterpreting the above equations to compare to R lead to the equation: 
        p(k) = (k - alphap)/(n + 1 - alphap - betap)
    
    Typical values of (alphap,betap) are:
    - (0,1) : p(k) = k/n : linear interpolation of cdf (R type 4)
    - (.5,.5) : p(k) = (k - 1/2.)/n : piecewise linear function (R type 5)
    - (0,0) : p(k) = k/(n+1) : (R type 6)
    - (1,1) : p(k) = (k-1)/(n-1): p(k) = mode[F(x[k])]. (R type 7, R default)
    - (1/3,1/3): p(k) = (k-1/3)/(n+1/3): Then p(k) ~ median[F(x[k])]. The resulting quantile estimates are approximately median-unbiased regardless of the distribution of x. (R type 8)
    - (3/8,3/8): p(k) = (k-3/8)/(n+1/4): Blom. The resulting quantile estimates are approximately unbiased if x is normally distributed (R type 9)
    - (.4,.4) : approximately quantile unbiased (Cunnane)
    - (.35,.35): APL, used with PWM
    
    Parameters default:
    * R:        quantile(x, probs = seq(0, 1, 0.25), na.rm = FALSE, names = TRUE, type = 7)
    * Python:   mquantiles(a, prob=[0.25, 0.5, 0.75], alphap=0.4, betap=0.4, axis=None, limit=())
    """