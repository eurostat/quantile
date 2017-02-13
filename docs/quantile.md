Compute empirical quantiles of a variable with sample data corresponding to given probabilities. 

### Common Arguments

* `probs` : (_option_) list of probabilities with values in [0,1]; the smallest observation 
	corresponds to a probability of 0 and the largest to a probability of 1; default: 
	`probs=0 0.25 0.5 0.75 1`, so as to match default values `seq(0, 1, 0.25)` used in R 
	[quantile](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html); 
* `type` : (_option_) an integer between 1 and 11 selecting one of the nine quantile algorithms 
	discussed in Hyndman and Fan's article (see references) and detailed below to be used; 
	| `type` |                    description                                 |
	|:------:|:---------------------------------------------------------------|
	|    1   | inverted empirical CDF					                      |
	|    2   | inverted empirical CDF with averaging at discontinuities       |       
	|    3   | observation numberer closest to qN (piecewise linear function) | 
	|    4   | linear interpolation of the empirical CDF                      | 
	|    5   | Hazen's model (piecewise linear function)                      | 
	|    6   | Weibull quantile                                               |
	|    7   | interpolation points divide sample range into n-1 intervals    |
	|    8   | unbiased median (regardless of the distribution)               |
	|    9   | approximate unbiased estimate for a normal distribution        |
	|   10   | Cunnane's definition (approximately unbiased)                  |
	|   11   | Filliben's estimate                                            |

### Algorithm

All sample quantiles are defined as weighted averages of consecutive order statistics. Sample 
quantiles of type `i` are defined for `1 <= i <= 9` by:
	Q[i](p) = (1 - gamma) * x[j] + gamma *  x[j+1]
where `x[j]`, for `(j-m)/N<=p<(j-m+1)/N`, is the `j`-th order statistic, `N` is the sample 
size, the value of `gamma` is a function of:
	j = floor(N*p + m)
	g = N*p + m - j
and `m` is a constant determined by the sample quantile type. 
For types 1, 2 and 3, `Q[i](p)` is a discontinuous function:
| `type` |     `p[k]`    |   `m`   |`alphap`|`betap`|	             `gamma`               | 
|:------:|:-------------:|:-------:|:------:|:-----:|:------------------------------------:|
|    1   |     `k/N`     |    0    |    0   |   0   | 1 if `g>0`, 0 if `g=0`               |
|    2   |     `k/N`     |    0    |    .   |   .   | 1/2 if `g>0`, 0 if `g=0`             | 
|    3   |  `(k+1/2)/N`  |  -1/2   |   1/2  |   0   | 0 if `g=0` and `j` even, 1 otherwise | 
For types 4 through 9, `Q[i](p)` is a continuous function of `p`, with `gamma` and `m` given 
below. The sample quantiles can be obtained equivalently by linear interpolation between the 
points `(p[k],x[k])` where `x[k]` is the `k`-th order statistic:
| `type` |       `p[k]`       |      `m`     |`alphap`|`betap`|`gamma`| 
|:------:|:------------------:|:------------:|:------:|:-----:|:-----:|
|    4   |        `k/N`       |       0      |    0   |   0   |  `g`  | 
|    5   |     `(k-1/2)/N`    |      1/2     |   1/2  |   0   |  `g`  | 
|    6   |       `k/(N+1)`    |      `p`     |    0   |   1   |  `g`  | 
|    7   |    `(k-1)/(N-1)`   |     `1-p`    |    1   |  -1   |  `g`  | 
|    8   |  `(k-1/3)/(N+1/3)` |   `(1+p)3`   |   1/3  |  1/3  |  `g`  | 
|    9   |  `(k-3/8)/(N+1/4)` |  `(2*p+3)/8` |   3/8  |  1/4  |  `g`  | 
|   10   |   `(k-.4)/(N+.2)`  |   `.2*p+.4`  |    .4  |   .4  |  `g`  |
|   11   |`(k-.3175)/(N+.365)`|`.365*p+.3175`| .3175  | .3175 |  `g`  |
In the above tables, the `(alphap,betap)` pair is defined such that:
	p[k] = (k - alphap)/(n + 1 - alphap - betap)
	
### References

1. Makkonen, L. and Pajari, M. (2014): ["Defining sample quantiles by the true rank probability"](https://www.hindawi.com/journals/jps/2014/326579/cta/).
2. Hyndman, R.J. and Fan, Y. (1996): ["Sample quantiles in statistical packages"](http://www.jstor.org/stable/2684934). 
3. Cunnane, C. (1978): ["Unbiased plotting positions: a review, Journal of Hydrology"](http://www.sciencedirect.com/science/article/pii/0022169478900173).
4. Barnett, V. (1975): ["Probability plotting methods and order statistics"](http://www.jstor.org/stable/2346708).
5. Filliben, J.J. (1975): ["The probability plot correlation coefficient test for normality"](http://www1.cmc.edu/pages/faculty/MONeill/Math152/Handouts/filliben.pdf).
