/* quantile_source.c
 *
 * Description:
 * Compute empirical quantiles of a sample data array corresponding to given 
 * probabilities. 
 * 
 * Usage:
 *
 *    double *quantile_<TYPE>_from_gsl) (<TYPE> data[],  size_t N,
 *                                       const double probs[], size_t n,
 *			                 int type);    
 *
 * About:
 * This code is intended as a proof of concept for the following publication:
 *    Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
 *    in Proc. New Techniques and Technologies for Statistics.
 *
 * Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
 * Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
 */

#include <stdlib.h>
#include <math.h>

#include <gsl/gsl_sort.h>

#include "quantile.h"

/* J_INDICE: j = floor(n*p + m) */
#define J_INDICE(p, n, m) math.floor(n*p + m);
/* G_INDICE: g = n*p + m - j */
#define G_INDICE(p, n, m, j) (n*p + m - j);
/* P_INDICE: p(k)=(k-alphap)/(n+1-alphap-betap) */
#define P_INDICE(k, alphap, betap, n) (k-alphap) / (n+1-alphap-betap);
/* M_INDICEP: m = alphap + p*(1 - alphap - betap) */
#define M_INDICEP(p, alphap, betap) alphap + p * (1 - alphap - betap);	

inline double M_INDICE(p, i) {
  if (i==1 || i==2 || i==4) { m = 0; }
  else if (i==3)            { m = -0.5; }
  else if (i==5)            { m = 0.5; }
  else if (i==6)            { m = p; }
  else if (i==7)            { m = (1-p); }
  else if (i==8)            { m = (p+1)/3; }
  else if (i==9)            { m = (2*p+3)/8; }
  else if (i==10)           { m = .4 + .2 * p; }
  else if (i==11)           { m = .3175 + .365 * p; }
  return m;
}
	
inline double GAMMA_INDICE(g, j, type) {
  if (type == 1) {
    if (g > 0.)             gamma = 1.;
    else                    gamma = 0.;
  } else if (type == 2) {
    if (g > 0.)             gamma = 1.;
    else                    gamma = 0.5;
  } else if (type == 3) {
    if (g == 0 && j%2 == 0) gamma = 0.;
    else                    gamma = 1.;
  } else if (type >= 4)      
    gamma = g;
  return gamma
}
				
double *
FUNCTION(quantile,from_gsl) (BASE data[], 
                            size_t N,
        			      const double probs[],
                            size_t q,
        			      int type)
{
  int i;
  long j, firstobs, obs;
  double m, g, gamma;
  double *quant;

  if( (quant=(double*)malloc(n*sizeof(double))) == NULL)
    {
      GSL_ERROR_NULL ("failed to allocate space for quantile", GSL_ENOMEM);
      return NULL;
    }   

  gsl_sort(data, 1, N);

  for (i=0; i<q; i++) {
    /* for given p probability, compute the (p,m,j) indices and extract the 
     * sorted (x1,x2)=(x[j],x[j+1]) pair */
    m =	M_INDICE(probs[i], type);
    j = J_INDICE(probs[i], N, m);
    g = G_INDICE(probs[i], N, m, j);

    if (j == 0) firstobs = obs = 0;
    else if (j == N) 	firstobs = obs = N-1;
    else {
      firstobs = j;
      obs = j + 1;
    }

    /* run the calculation for estimating the gamma index, plus the final 
     * quantile value */
    gamma = GAMMA_INDICE(g, j, type);
    quant[i] = (1. - gamma) * data[firstobs] + gamma * data[obs];
  }

  return quant;
}
