/** 
## quantile {#sas_quantile}
Compute empirical quantiles of a variable with sample data corresponding to given probabilities. 
	
	%quantile(var, probs=, _quantiles_=, names=, type=7, method=DIRECT,  
		idsn=, odsn=, ilib=WORK, olib=WORK, na_rm = YES);

### Arguments
* `var` : data whose sample quantiles are estimated; this can be either:
		+ the name of the variable in a dataset storing the data; in that case, the parameter 
			`idsn` (see below) should be set; 
		+ a list of (blank separated) numeric values;
* `probs` : (_option_) list of probabilities with values in [0,1]; the smallest observation 
	corresponds to a probability of 0 and the largest to a probability of 1; in the case 
	`method=INHERIT` (see below), these values are multiplied by 100 in order to be used by 
	`PROC UNIVARIATE`; default: `probs=0 0.25 0.5 0.75 1`, so as to match default values 
	`seq(0, 1, 0.25)` used in R 
	[quantile](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html); 
* `type` : (_option_) an integer between 1 and 11 selecting one of the nine quantile algorithms 
	discussed in Hyndman and Fan's article (see references) and detailed below to be used; 
	| `type` |                    description                                 | `PCTLDEF` |
	|:------:|:---------------------------------------------------------------|:---------:|
	|    1   | inverted empirical CDF					  |     3     |
	|    2   | inverted empirical CDF with averaging at discontinuities       |     5     |        
	|    3   | observation numberer closest to qN (piecewise linear function) |     2     | 
	|    4   | linear interpolation of the empirical CDF                      |     1     | 
	|    5   | Hazen's model (piecewise linear function)                      |   _n.a._  | 
	|    6   | Weibull quantile                                               |     4     | 
	|    7   | interpolation points divide sample range into n-1 intervals    |   _n.a._  | 
	|    8   | unbiased median (regardless of the distribution)               |   _n.a._  | 
	|    9   | approximate unbiased estimate for a normal distribution        |   _n.a._  |
	|   10   | Cunnane's definition (approximately unbiased)                  |   _n.a._  |
	|   11   | Filliben's estimate                                            |   _n.a._  |

	default: `type=7` (likewise R `quantile`);
* `method` : (_option_) choice of the implementation of the quantile estimation method; this can 
	be either:
		+ `INHERIT` for an estimation based on the use of the `PROC UNIVARIATE` procedure already
			implemented in SAS,
		+ `DIRECT` for a canonical implementation based on the direct transcription of the various
			quantile estimation algorithms (see below) into SAS language;

	note that the former (`method=INHERIT`) is incompatible with `type` other than `(1,2,3,4,6)` since 
	`PROC UNIVARIATE` does actually not support these quantile definitions (see table above); in the 
	case `type=5`, `7`, `8`, or `9`, `method` is then set to `DIRECT`; default: `method=DIRECT`;
* `idsn` : (_option_) when input data is passed as a variable name, `idsn` represents the dataset
	to look for the variable `var` (see above);
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used if `idsn` is 
	set;
* `olib` : (_option_) name of the output library (see `names` below); by default: empty, _i.e._ `WORK` 
	is also used when `odsn` is set;
* `na_rm` : (_obsolete_) logical; if true (`yes`), any NA and NaN's are removed from x before the quantiles 
	are computed.

### Returns
Return estimates of underlying distribution quantiles based on one or two order statistics from 
the supplied elements in `var` at probabilities in `probs`, following quantile estimation algorithm
defined by `type`. The output sample quantile are stored either in a list or as a table, through:
* `_quantiles_` : (_option_) name of the output numeric list where quantiles are stored in increasing
	`probs` order; incompatible with parameters `odsn` and `names `below;
* `odsn, names` : (_option_) respective names of the output dataset and variable where quantiles are 
	stored; if both `odsn` and `names` are set, the quantiles are saved in the `names` variable ot the
	`odsn` dataset; if just `odsn` is set, then they are stored in a variable named `QUANT`; if 
	instead only `names` is set, then the dataset will also be named after `names`.

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
3. Barnett, V. (1975): ["Probability plotting methods and order statistics"](http://www.jstor.org/stable/2346708).
 
### See also
[%io_quantile](@ref sas_io_quantile),
[UNIVARIATE](https://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#univariate_toc.htm),
[quantile (R)](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html),
[mquantiles (scipy)](https://docs.scipy.org/doc/scipy-0.18.1/reference/generated/scipy.stats.mstats.mquantiles.html),
[gsl_stats_quantile* (C)](https://www.gnu.org/software/gsl/manual/html_node/Median-and-Percentiles.html).
*/ /** \cond */

/*
### About
This code is intended as a supporting material for the following publication:
* Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

### Notice
Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
*/

%global _FORCE_STANDALONE_;

%macro quantile(var			/* Name of the input variable/list 		(REQ) */
		, probs=		/* List of probabilities 			(OPT) */
		, type=			/* Type of interpolation considered 		(OPT) */
		, method=		/* Flag used to select the estimation method 	(OPT) */
		, names=		/* Output name of variable/dataset 		(OPT) */
		, _quantiles_=		/* Name of the output variable 			(OPT) */
		, idsn=			/* Name of input dataset 			(OPT) */
		, ilib=			/* Name of input library 			(OPT) */
		, odsn=			/* Name of output dataset 			(OPT) */
		, olib=			/* Name of output library 			(OPT) */
		, na_rm =		/* Dummy variable 				(OPT) */
		);
	%local _mac;
	%let _mac=&sysmacroname;

	%if &_FORCE_STANDALONE_ EQ %then %let _FORCE_STANDALONE_=1;

	%if %symexist(G_PING_ROOTPATH) EQ 1 %then %do; 
		%macro_put(&_mac);
	%end;
	%else %if %symexist(G_PING_ROOTPATH) EQ 0 or &_FORCE_STANDALONE_ EQ 1 %then %do; 
		/* "dummyfied" macros */
		%macro error_handle/parmbuff;	0 /* always OK, nothing will ever be checked */
		%mend;
		%macro ds_check/parmbuff; 		0 /* always OK */
			/*%macro ds_check(d, lib=); 		
				%if %sysfunc(exist(&lib..&d, data)) or %sysfunc(exist(&lib..&d,view)) %then %do;	0 
				%end;
			  	%else %do;										1
				%end;
			%mend;*/
		%mend;
		%macro var_check/parmbuff; 		0 /* always OK */
		%mend;
		%macro par_check/parmbuff; 		0 /* always OK */
			/*%macro par_check(p, type=, range=, set=); 	
				%list_ones(%list_length(&p), item=0)
			%mend;*/
		%mend;
		%macro list_sort(l, _list_=); /* does nothing */
			data _null_;	call symput("&_list_","&l");
			run;
		%mend;
		/* simplified macros */
		%macro macro_isblank(v);
			%let __v = %superq(&v);
			%let ___v = %sysfunc(compbl(%quote(&__v))); 
			%if %sysevalf(%superq(__v)=, boolean) or %nrbquote(&___v) EQ 	%then %do;			1
			%end;
			%else %do;											0
			%end;
		%mend;
		%macro list_quote(l, mark=, sep=%quote( ), rep=%quote(, ));
			%sysfunc(tranwrd(%qsysfunc(compbl(%sysfunc(strip(&l)))), &sep, &rep))
		%mend;
		%macro list_length(l, sep=%quote( ));
			%sysfunc(countw(&l, &sep))
		%mend;
		%macro list_ones(l, item=, sep=%quote( ));
			%let ol=&item;
			%do i=2 %to &l;
				%let ol=&ol.&sep.&item;
			%end;
			&ol
		%mend;
		%macro list_apply(l, macro=, _applst_=, sep=%quote( ));
			%let ol=%&macro(%scan(&l, 1, &sep));
			%do i=2 %to %list_length(&l, sep=&sep);	
				%let ol=&ol %&macro(%scan(&l, &i, &sep));
			%end;
			data _null_;	call symput("&_applst_","&ol");
			run;
		%mend;
		%macro list_sequence(start=, step=, end=, sep=%quote( ));
			%let ol=&start;
			%let len=%sysevalf((&end - &start)/&step + 1, floor);
			%do _i=1 %to %eval(&len-1);
				%let ol=&ol.&sep.%sysevalf(&start + &_i * &step);
			%end;
			&ol
		%mend;
		%macro list_to_var(v, n, d, fmt=, sep=%quote( ), lib=WORK);
			DATA &lib..&d;
				ATTRIB &n FORMAT=&fmt;
				i=1;
				do while (scan("&v",i,"&sep") ne "");
					&n=scan("&v",i,"&sep"); output;
					i + 1;
				end;
				drop i eof;
		   	run; 
		%mend;
		%macro work_clean/parmbuff;
			%let i=1;
   			%do %while(%scan(&syspbuff,&i) ne);			
				PROC DATASETS lib=WORK nolist; DELETE %scan(&syspbuff,&i); quit;
	   			%let i=%eval(&i+1);
			%end;
		%mend;
	%end;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local SEP 
		isdsntmp
		varname
		nprobs
		minval maxval;
	%let isdsntmp=	NO;
	%let SEP=		%quote( );

	%local MACHINE_EPSILON
		QU_METHODS
		R_QU_METHOD
		SAS_QU_METHOD;
	%let QU_METHODS=		1 2 3 4 5 6 7 8 9;
	%let R_DEF_QU_METHOD=	7;
	%let SAS_QU_METHODS=	1 2 3 4 6;
	%let SAS_DEF_QU_METHOD=	3;
	%let DEF_QU_METHOD=		&R_DEF_QU_METHOD;
	%let MACHINE_EPSILON = 	%sysevalf(1./10**14); /* likewise R */

	/* shall we use low-level macros from PING, or not?
	 * find out about it here: https://gjacopo.github.io/PING */

	/* ILIB/IDSN: some basic error checkings... */
	%if not %macro_isblank(idsn) %then %do;
		%if %macro_isblank(ilib) %then 	
			%let ilib=WORK;
		%if %error_handle(ErrorInputDataset, 
				%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
				txt=%quote(!!! Input dataset %upcase(&idsn) not found !!!)) %then
			%goto exit;
	%end;

	/* VAR: check/set */
	%if %macro_isblank(idsn) %then %do;
		%local isdsntmp=YES;
		%let idsn=TMP&_mac;
		%let varname=_DUMMY_;
		%list_to_var(&var, &varname, &idsn, fmt=NUMERIC, sep=&SEP, lib=WORK);
	%end; 
	%else %do;	
		%if %error_handle(ErrorInputDataset, 
				%var_check(&idsn, &var, lib=&ilib) NE 0, mac=&_mac,		
				txt=%quote(!!! Input variable %upcase(&var) not found in %upcase(&idsn) !!!)) %then
			%goto exit;
		%let varname=&var;
	%end; 

	/* TYPE: check/set */
	%if %macro_isblank(type) %then 	%let type=&DEF_QU_METHOD;
	%if %error_handle(ErrorInputParameter, 
			%par_check(&type, type=NUMERIC, set=&QU_METHODS) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter for TYPE interpolation method selection !!!)) %then
		%goto exit;

	/* METHOD: check/set */
	%if %macro_isblank(method) %then 	%let method=DIRECT;
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&method), type=CHAR, set=DIRECT INHERIT) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter for METHOD calculation method selection !!!)) %then
		%goto exit;
	%let method=%upcase(&method);

	/* METHOD/TYPE: check compatibility */
	%if "&method"="INHERIT" %then %do;
		%if %error_handle(WarningInputParameter, 
				%par_check(&type, type=CHAR, set=&SAS_QU_METHODS) NE 0, mac=&_mac,		
				txt=%quote(!!! Interpolation type &type incompatible with method based on UNIVARIATE procedure - DIRECT method used instead !!!),
				verb=warn) %then %do;
			%let method=DIRECT;
			%goto warning1; /* dummy/useless here ... */
		%end;
		%warning1:
	%end;

	/* PROBS: check/set */
	%if %macro_isblank(probs) %then 
		%let probs=%list_sequence(start=0, step=0.25, end=1); 
	%let nprobs=%list_ones(%list_length(&probs, sep=&SEP), item=0);

	%let minval=%sysevalf(-&MACHINE_EPSILON);
	%let maxval=%sysevalf(1+&MACHINE_EPSILON);
	%if %error_handle(ErrorInputParameter, 
			%par_check(&probs, type=NUMERIC, range=&minval &maxval, set=0 1) NE &nprobs, mac=&_mac,		
			txt=%quote(!!! Wrong parameter for PROBS method selection !!!)) %then
		%goto exit;
	%list_sort(&probs, _list_=probs); /* just to be sure... */

	/* NAMES/_QUANTILES_: some basic error checkings... */
	%if %error_handle(ErrorInputParameter, 
		%macro_isblank(names) EQ 0 and %macro_isblank(_quantiles_) EQ 0, mac=&_mac,
		txt=%quote(!!! Parameters NAMES and _QUANTILES_ are incompatible !!!)) 
			or
			%error_handle(ErrorInputParameter, 
			%macro_isblank(names) EQ 1 and %macro_isblank(_quantiles_) EQ 1 and %macro_isblank(odsn) EQ 1, mac=&_mac,
			txt=%bquote(!!! One at least among parameters NAMES, ODSN and _QUANTILES_ must be set !!!)) %then 
		%goto exit;

	/* OLIB/ODSN: some basic error checkings... */
	%if %macro_isblank(olib) %then 	%let olib=WORK; /* always declared, unlike ilib */
	%if not %macro_isblank(odsn) %then %do;
		%if %error_handle(ErrorOutputDataset, 
				%ds_check(&odsn, lib=&olib) NE 0, mac=&_mac,		
				txt=%quote(! Output dataset %upcase(&odsn) already exists !), verb=warn) %then
			%goto warning2;
	%end;
	%warning2:

	/* NA_RM: ignored */
	%let na_rm=TRUE;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	
	%local qname
		tmp;
	%let tmp=		QU_&_mac;
	%let qname=		QUANT;

	%if "&method"="INHERIT" %then %do;
		/* implementation based on existing PROC UNIVARIATE */
		%macro _quantile_univariate(var, probs=, type=, qname=, idsn=, ilib=, odsn=, olib=);

			%local tmp
				pctlpts
				pctldef;
			%let tmp=TMP&sysmacroname;
			%let pctlpts=;

			/* define the quantiles according to SAS format (statement pctlpts) */
			%macro defquant(x); %sysevalf(&x*100.) %mend;
			%list_apply(&probs, macro=defquant, _applst_=pctlpts);
			%let pctlpts=%list_quote(&pctlpts, mark=_EMPTY_, rep=%quote(, ));

			/* define the method according to SAS definition (statement pctldef) */
			%macro deftype(type);
				/* DATA _map_method;
					type=1; sas_type=3; output;
					type=2; sas_type=5; output;
					type=3; sas_type=2; output;
					type=4; sas_type=1; output;
					type=6; sas_type=4; output;
				run; */
				%if &type=1 %then %do;
					3
				%end; 
				%else %if &type=2 %then %do;
					5
				%end; 
				%else %if &type=3 %then %do;
					2
				%end; 
				%else %if &type=4 %then %do;
					1
				%end; 
				%else %if &type=6 %then %do;
					4
				%end; 
			%mend;
			%let pctldef=%deftype(&type);

			/* run the UNIVARIATE macro */
			ods results off; /* we choose not to display the "default" quantile values */
			ods select Quantiles;
			PROC UNIVARIATE data=&ilib..&idsn  pctldef = &pctldef;
			   VAR &varname;
			   OUTPUT out=&tmp pctlpre=&qname._ pctlpts = &pctlpts; /* pctlpre is dummy here */
			run;
			ods results on; /* reactivate */

			/* run TRANSPOSE to format the quantile table */
			PROC TRANSPOSE data=&tmp out=&olib..&odsn(drop=_NAME_ _LABEL_) prefix=&qname;
			run;
			
			/* some adjustment... */
			DATA &olib..&odsn;
				SET &olib..&odsn(rename=(&qname.1=&qname));
			run;

			/* clean your shit */
			%work_clean(&tmp);

		%mend _quantile_univariate;
		/* run the macro */
		%_quantile_univariate(&var, probs=&probs, type=&type, qname=&qname, 
			idsn=&idsn, ilib=&ilib, odsn=&tmp, olib=WORK);
	%end;

	%else %if "&method"="DIRECT" %then %do;
		/* canonical implementation as a direct retranscription of the algorithm */
		%macro _quantile_canonical(var, probs=, type=, qname=, idsn=, ilib=, odsn=, olib=);

			%local i i1 i2
				SEP
				tmp
				N Q gamma
				p m j g 
				nprobs;
			%let SEP=%quote( );
			%let nprobs=%list_length(&probs, sep=&SEP);
			%let tmp=TMP&sysmacroname;

			/* some macro definition */
			%macro p_indice(k, alphap, betap, n);	/* p(k) = (k - alphap)/(n + 1 - alphap - betap) */
				%sysevalf((&k - &alphap)/(&n + 1 - &alphap - &betap))
				/* (alphap, betap) =
					* (0,1) : p(k) = k/n : linear interpolation of cdf (R type 4)
					* (.5,.5) : p(k) = (k - 1/2.)/n : piecewise linear function (R type 5)
					* (0,0) : p(k) = k/(n+1) : (R type 6)
					* (1,1) : p(k) = (k-1)/(n-1): p(k) = mode[F(x[k])]. (R type 7, R default)
					* (1/3,1/3): p(k) = (k-1/3)/(n+1/3): Then p(k) ~ median[F(x[k])]; resulting quantile 
						estimates are approximately median-unbiased regardless of the distribution of x 
						(R type 8)
					* (3/8,3/8): p(k) = (k-3/8)/(n+1/4): Blom. The resulting quantile estimates are 
						approximately unbiased if x is normally distributed (R type 9) */
			%mend p_indice;

			%macro m_indice(p, i=, alphap=, betap=);	/* m = alphap + p*(1 - alphap - betap) */
				%local m;
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
			%mend m_indice;

			%macro j_indice(p, n, m);				/* j = floor(n*p + m) */
				%sysfunc(floor(%sysevalf(&n*&p + &m)))
			%mend j_indice;

			%macro g_indice(p, n, m, j);			/* g = n*p + m - j */
				%sysevalf(&n*&p + &m - &j)
			%mend g_indice;

			/* sort the values in the table */
			PROC SORT DATA=&ilib..&idsn OUT=&tmp(keep=&var);
		  		BY &var;
			run;

			/* count the number of observations */
			PROC SQL noprint;
			   	SELECT count(*) into :N FROM &tmp;
			quit;

			/* run the first calculation for estimating the (j,g) pair together with 
			* corresponding (x_j,x_{j+1}) sorted items */
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
				%else %do;
					PROC APPEND base=&olib..&odsn data=s_&tmp;
			    	run;
				%end;
			%end;

			/* run the second calculation for estimating the gamma index, plus the final 
			* quantile value */
			DATA &olib..&odsn(keep=&qname);
				SET &olib..&odsn;
				%if &type EQ 1 %then %do;
					if g GT 0 then 					gamma=1;
					else 							gamma=0;
				%end;
				%else %if &type EQ 2 %then %do;
					if g GT 0 then 					gamma=1;
					else /* if g=0 */				gamma=0.5;
				%end;
				%else %if &type EQ 3 %then %do;
					if g EQ 0 and mod(j,2)=0 then	gamma=0;
					else 							gamma=1;
				%end;
				%else %if &type GE 4 %then %do;
					gamma=&g;
				%end;
				&qname = (1-gamma) * x1 + gamma * x2;
			run;
				
			/* clean your shit */
			%work_clean(&tmp, s_&tmp);

	%mend _quantile_canonical;
		/* run the macro */
		%_quantile_canonical(&var, probs=&probs, type=&type, qname=&qname, 
			idsn=&idsn, ilib=&ilib, odsn=&tmp, olib=WORK);
	%end;

	/* save whatever has to be saved... */
	%if not %macro_isblank(_quantiles_) %then %do;
		PROC SQL noprint;	
			SELECT &qname into :&_quantiles_ SEPARATED BY ' '
			FROM &tmp;
		quit;
	%end;
	%else %do;
		%if not %macro_isblank(names) %then %do;
			%if %macro_isblank(odsn) %then 	%let odsn=&names;
		%end;
		DATA &olib..&odsn;
			SET &tmp; 
			%if "&names"^="&qname" %then %do;
				RENAME &qname=&names;
			%end;
		run;
	%end; 

	/* get rid of the temporary table(s) */
	*%work_clean(&tmp); 

	%quit:
	%work_clean(&tmp); 
	%if &isdsntmp=YES %then %do; %work_clean(&idsn); %end;

	%exit:
%mend quantile;

%macro _example_quantile;
	%if %symexist(G_PING_ROOTPATH) EQ 0 and &_FORCE_STANDALONE_ EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn N;
	%let dsn=TMP&sysmacroname;	
	%let N=1000;

	data &dsn;
		call streaminit(123);       /* set random number seed */
		do i = 1 to &N;
   			u = rand("Uniform");     /* u ~ U(0,1) */
   			output;
		end;
	run;

	%let quantiles=;
	%let type=1;
	%let probs=0.001 0.005 0.01 0.02 0.05 0.10 0.50;
	%put (i) Test with probs=&probs, type=&type and method=INHERIT;
	%quantile(u, probs=&probs, _quantiles_=quantiles, type=&type, idsn=&dsn, ilib=WORK, method=INHERIT);
	%put quantiles=&quantiles;

	%let quantiles=; /* reset */
	%let probs=0.00 0.25 0.50 0.75 1.00;
	%put (ii) Test with probs=&probs, type=&type and method=DIRECT;
	%quantile(u, probs=&probs, _quantiles_=quantiles, type=&type, idsn=&dsn, ilib=WORK, method=DIRECT);
	%put quantiles=&quantiles;

	%put;
	PROC DATASETS lib=WORK nolist; DELETE &dsn; quit;
%mend _example_quantile;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_quantile; 
*/

/** \endcond */
