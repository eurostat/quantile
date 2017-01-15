/* quantile_source.c
 * 
 */


double
FUNCTION(gsl_stats,quantile) (const BASE data[], 
                              const size_t stride,
                              const size_t n,
                              const double f)
{
  const double index = f * (n - 1) ;
  const size_t lhs = (int)index ;
  const double delta = index - lhs ;
  double result;

#define j_indice(p, n, m) math.floor(n*p+m) /* j = floor(n*p + m) */;

#define g_indice(p, n, m, j) (n*p + m - j) /* g = n*p + m - j */;

#define p_indice(k, alphap, betap, n) (k-alphap)/(n+1-alphap-betap); /* p(k)=(k-alphap)/(n+1-alphap-betap) */

#define m_indice(p, i, alphap, betap);	/* m = alphap + p*(1 - alphap - betap) */
				%if "&i"^="" %then %do;
					%if &i=1 or &i=2 or &i=4 %then 				%let m=0;
					%else %if &i=3 %then 						%let m=-0.5;
					%else %if &i=5 %then 						%let m=0.5;
					%else %if &i=6 %then 						%let m=&p;
					%else %if &i=7 %then 						%let m=%sysevalf(1-&p);
					%else %if &i=8 %then 						%let m=%sysevalf((&p+1)/3);
					%else %if &i=9 %then 						%let m=%sysevalf((2*&p+3)/8);
				%end;
				%else %if "&alphap"^="" and "&betap"^="" %then
					%let m = %sysevalf(&alphap + &p*(1 - &alphap - &betap));
				&m

			%do i=1 %to &nprobs;
				/* for given p probability, compute the (p,m,j) indices and extract the 
				* sorted (x1,x2)=(x_j,x_{j+1}) pair */
				%let p = 	%scan(&probs, &i, &SEP);
				%let m =	%m_indice(&p, i=&type);
				%let j = 	%j_indice(&p, &N, &m);
				%let g = 	%g_indice(&p, &N, &m, &j);
				DATA s_&tmp(drop=&var)/*(keep= j g x1 x2)*/;
					%if &j EQ 0 %then %do;			
						SET &tmp(firstobs=1 obs=1) end=eof;
					%end;
					%else %if &j EQ &N %then %do;			
						SET &tmp(firstobs=&N obs=&N) end=eof;
					%end;
					%else %do;
						SET &tmp(firstobs=&j obs=%eval(&j+1)) end=eof;
					%end;
					j  =	&j;
					g  = 	&g;
					x1 = 	lag1(&var);
					x2 = 	&var; 	
					if missing(x1) then 	x1=&var;
					if eof then do;
						output;
					end;
				run;
				/* create/append the ith result to previously computed quantile values */
				%if &i=1 %then %do;
					DATA &olib..&odsn; SET s_&tmp;
			    	run;
				%end;

			/* run the second calculation for estimating the gamma index, plus the final 
			* quantile value */
			DATA &olib..&odsn(keep=&qname);
				SET &olib..&odsn;
				%if &type=1 %then %do;
					if g GT 0 then 					gamma=1;
					else 							gamma=0;
				%end;
				%else %if &type=2 %then %do;
					if g GT 0 then 					gamma=1;
					else /* if g=0 */				gamma=0.5;
				%end;
				%else %if &type=3 %then %do;
					if g EQ 0 and mod(j,2)=0 then 	gamma=0;
					else 							gamma=1;
				%end;
				%else %if &type GE 4 %then 			gamma=&g;
				&qname = (1-gamma) * x1 + gamma * x2;
			run;


  if (n == 0)
    return 0.0 ;

  if (lhs == n - 1)
    {
      result = data[lhs * stride] ;
    }
  else 
    {
      result = (1 - delta) * sorted_data[lhs * stride] + delta * sorted_data[(lhs + 1) * stride] ;
    }

  return result ;
}
