##### <a name="Algorithms"></a>Detailed algorithms

Eleven quantile algorithms are made available: 9 are discussed in Hyndman and Fan's, 1 in Cunnane's and 1 in Filliben's articles (see [references](#References)):

| `type` |                    description                                
|:------:|:--------------------------------------------------------------
|    1   | inverted empirical CDF                           			 
|    2   | inverted empirical CDF with averaging at discontinuities             
|    3   | observation numberer closest to qN (piecewise linear function) 
|    4   | linear interpolation of the empirical CDF                     
|    5   | Hazen's model (piecewise linear function)                     
|    6   | Weibull quantile                                             
|    7   | interpolation points divide sample range into n-1 intervals
|    8   | unbiased median (regardless of the distribution)             
|    9   | approximate unbiased estimate for a normal distribution  
|   10   | Cunnane's definition (approximately unbiased)
|   11   | Filliben's estimate

All sample quantiles are defined as weighted averages of consecutive order statistics. Sample quantiles of type `i` are defined for `1 <= i <= 10` by:

	Q[i](p) = (1 - gamma) * x[j] + gamma *  x[j+1]
	
where `x[j]`, for `(j-m)/N<=p<(j-m+1)/N`, is the `j`-th order statistic, `N` is the sample size, the value of `gamma` is a function of:

	j = floor(N*p + m)
	g = N*p + m - j
	
and `m` is a constant determined by the sample quantile type. 

For types 1, 2 and 3, `Q[i](p)` is a discontinuous function:

| `type` |   `p[k]`    |   `m`  |`alphap`|`betap`|	          `gamma`               | 
|:------:|:-----------:|:------:|:------:|:-----:|:------------------------------------:|
|    1   |    `k/N`    |    0   |    0   |   1   | 1 if `g>0`, 0 if `g=0`               |
|    2   |    `k/N`    |    0   |    0   |   1   | 1/2 if `g>0`, 0 if `g=0`             | 
|    3   | `(k+1/2)/N` |   -.5  |   -.5  |  -1.5 | 0 if `g=0` and `j` even, 1 otherwise | 

For types 4 through 11, `Q[i](p)` is a continuous function of `p`, with `gamma` and `m` given below. The sample quantiles can be obtained equivalently by linear interpolation between the points `(p[k],x[k])` where `x[k]` is the `k`-th order statistic:

| `type` |      `p[k]`        |      `m`     |`alphap`|`betap`|`gamma`| 
|:------:|:------------------:|:------------:|:------:|:-----:|:-----:|
|    4   |        `k/N`       |       0      |    0   |   1   |  `g`  | 
|    5   |     `(k-1/2)/N`    |       .5     |    .5  |   .5  |  `g`  | 
|    6   |       `k/(N+1)`    |      `p`     |    0   |   0   |  `g`  | 
|    7   |    `(k-1)/(N-1)`   |     `1-p`    |    1   |   1   |  `g`  | 
|    8   |  `(k-1/3)/(N+1/3)` |   `(1+p)3`   |   1/3  |  1/3  |  `g`  | 
|    9   |  `(k-3/8)/(N+1/4)` |  `(2*p+3)/8 `|   3/8  |  3/8  |  `g`  | 
|   10   |   `(k-.4)/(N+.2)`  |   `.2*p+.4`  |    .4  |   .4  |  `g`  |
|   11   |`(k-.3175)/(N+.365)`|`.365*p+.3175`| .3175  | .3175 |  `g`  |

In the above tables, the `(alphap,betap)` pair is defined such that:

	p[k] = (k - alphap)/(N + 1 - alphap - betap)

#####  <a name="References"></a>References

1. Makkonen L. and Pajari M. (2014): [**Defining sample quantiles by the true rank probability**](https://www.hindawi.com/journals/jps/2014/326579/cta/), _Journal of Probability and Statistics_, vol. 2014, Article ID 326579, doi:[10.1155/2014/326579](https://dx.doi.org/10.1155/2014/326579)
2. Hyndman R.J. and Fan Y. (1996): [**Sample quantiles in statistical packages**](https://www.amherst.edu/media/view/129116/original/Sample+Quantiles.pdf), _The American Statistician_, 50(4):361-365, doi:[10.2307/2684934](http://www.jstor.org/stable/2684934)
3. Cunnane C. (1978): [**Unbiased plotting positions: a review**](http://www.sciencedirect.com/science/article/pii/0022169478900173), _Journal of Hydrology_, 37(3-4):205-222, doi:[10.1016/0022-1694(78)90017-3](https://dx.doi.org/10.1016/0022-1694(78)90017-3).
4. Barnett V. (1975): **Probability plotting methods and order statistics**, _Journal of the Royal Statistical Society. Series C (Applied Statistics)_, 24(1):95-108, doi:[10.2307/2346708 ](http://www.jstor.org/stable/2346708).
5. Filliben J.J. (1975): [**The probability plot correlation coefficient test for normality**](http://www1.cmc.edu/pages/faculty/MONeill/Math152/Handouts/filliben.pdf), _Technometrics_, 17(1):111-117, doi:[10.2307/1268008](https://dx.doi.org/10.2307/1268008).
