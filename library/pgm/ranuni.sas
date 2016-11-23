/**
## ranuni {#sas_ranuni}
Generate a dataset of random numbers generated with a uniform distribution `U([0,1])`. A macro 
version of SAS `ranuni` function. 

	%ranuni(dsn, sampsize, a=, b=, seed=0, int=no, lib=WORK);

### Arguments
* `dsn` : name of the output dataset;
* `sampsize` : sample size, _i.e._ desired number of observations in the output dataset;
* `a, b` : (_option_) constants used to define the alternative distribution `U([a,b])`; if `b`
	is set and not `a`, then `a=0`; if `a` is set and not `b`, then `b=10`; default: neither
	`a`, nor `b` is set and only numbers ~ `U([0,1])` are generated;
* `seed` : (_option_) seed of the pseudo-random numbers generator; if seed<=0, the time of day 
	is used to initialize the seed stream; default: `seed=0`, _i.e._ a random seed is used;
* `int` : (_option_) boolean flag (`yes/no`) set to force integer numbers; default: `int=no`;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;

### Returns
It will create the following variables, with size `sampsize`, in the output dataset `dsn`:
	* `u` : uniformly distributed float numbers ~ `U([0,1])`,
	* `x` : uniformly distributed float numbers ~ `U([a,b])` if `a` and/or `b` are set,
	* `n` : integers uniformly distributed ~ `U([a,b])` if `a` and/or `b` are set and `int=yes`.

while an index variable `i` (sequence from 1 to `sampsize`) is also kept.

### Examples
The following commands:

	%let seed=1;
	%let sampsize=10;
	%ranuni(TMP, &sampsize, seed=&seed, int=yes);

allows us to generate (since we use a fixed seed `>0`) the table `TMP` of pseudo-random numbers below:
 1 |      u       | n
---|--------------|---
1  | 0.1849625698 | 2
2  | 0.9700887157 | 10
3  | 0.3998243061 | 4
4  | 0.2593986454 | 2
5  | 0.9216025779 | 10
6  | 0.9692773498 | 10
7  | 0.5429791731 | 5
8  | 0.5316917228 | 5
9  | 0.0497940262 | 0
10 | 0.0665665516 | 0

See `%%_example_ranuni` for examples.

### Note
In short, this macro runs the following DATA step:

	DATA &lib..&dsn;
		do i = 1 to &sampsize;
		   	u = ranuni(&seed);
			%if not %macro_isblank(a) and not %macro_isblank(b) %then %do;
				%if %upcase(&int)=YES %then %do;
				   	n = &a + floor((1+&b-&a)*u);
				%end;
				%else %do;
			   		x = &a + (&b-&a)*u;      
				%end;
			%end;
		   	output;
		end;
	run;

### See also
[RANUNI](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000202926.htm),
[RAND](http://support.sas.com/documentation/cdl/en/lefunctionsref/63354/HTML/default/viewer.htm#p0fpeei0opypg8n1b06qe4r040lv.htm).
*/ /** \cond */ 

%macro ranuni(dsn			/* Reference dataset 										(REQ) */					 
			, sampsize		/* Size of the sample, i.e. desired number of observations 	(REQ) */
			, a=, b=		/* Constants used to define the distribution 				(OPT) */
			, seed=			/* Seed of the pseudo-random numbers generator 				(OPT) */
			, int=no		/* Boolean flag set to force integer numbers 				(OPT) */
			, lib=			/* Input library 											(OPT) */
			);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if not %symexist(G_PING_MAX) %then 	%let G_PING_MAX=10; /* sorry, dummy... */

	%if %error_handle(ErrorInputParameter, 
			%par_check(&sampsize, type=INTEGER, range=0) NE 0, mac=&_mac,		
			txt=%quote(!!! Parameter SAMPSIZE must be a INTEGER >0 value - Got %upcase(&sampsize) instead !!!)) %then
		%goto exit;

	/* set default input/output libraries if not passed */
	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/* check that the input dataset actually exists */
	%if %error_handle(WarninOutputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&dsn) already exists !, verb=warn) %then
		%goto warning;
	%warning:

	%if not %macro_isblank(b) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&b, type=NUMERIC) NE 0, mac=&_mac,		
				txt=%quote(!!! Parameter B must be a NUMERIC value - Got %upcase(&b) instead !!!)) %then
			%goto exit;
		%if %macro_isblank(a) %then 			%let a=0;
	%end;
	%if not %macro_isblank(a) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&a, type=NUMERIC) NE 0, mac=&_mac,		
				txt=%quote(!!! Parameter A must be a NUMERIC value - Got %upcase(&a) instead !!!)) %then
			%goto exit;
		%if %macro_isblank(b) %then 			%let b=&G_PING_MAX;
	%end;

	%if &int=yes %then %do;
		%if %macro_isblank(a) %then 	%let a=0;
		%if %macro_isblank(b) %then 	%let b=&G_PING_MAX;
	%end;

	%if %macro_isblank(seed) %then 	%let seed=0;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	DATA &lib..&dsn/*(drop=i)*/;
		/* call streaminit(&seed); */
		do i = 1 to &sampsize;
		   	/* random numbers (uniformly distributed) in [0,1] */
		   	u = ranuni(&seed);/* u = rand("Uniform");    /* u ~ U([0,1]) */
			%if not %macro_isblank(a) and not %macro_isblank(b) %then %do;
				%if %upcase(&int)=YES %then %do;
				   	/* random integers in [a,b] */
				   	n = &a + floor((1+&b-&a)*u); /* uniform integer in [a,b] */
					/* k = ceil( b*u );      uniform integer in [1,b] */
				%end;
				%else %do;
			   		/* random numbers in [a,b] */
			   		x = &a + (&b-&a)*u;        /* u ~ U([a,b]) */
				%end;
			%end;
		   	output;
		end;
	run;

	%exit:
%mend ranuni;

%macro _example_ranuni;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn; 
	%let dsn=TMP%upcase(&sysmacroname);

	%let sampsize=-1;
	%put (i) Dummy test;
	%ranuni(&dsn, &sampsize, a=-1, b=1);
	%if %ds_check(&dsn) NE 0 %then 		%put OK: TEST PASSED - Dummy test crashes;
	%else 								%put ERROR: TEST FAILED - Dummy test passes;

	%let sampsize=1000;
	%let a=-1;
	%let b=1;
	%put;
	%put (ii) Check that the statistics of a sample of size &sampsize match the characteristics of a uniformly distributed population;
	%ranuni(&dsn, &sampsize, a=-1, b=1);
 	/* the sample data for the u and x variables should be uniformly distributed on [0,1] and [-1,1], respectively */
	PROC UNIVARIATE data=&dsn;
		VAR u x;
		histogram u/ endpoints=0 to 1 by 0.05;
		histogram x/ endpoints=&a to &b by 0.1;
	run;

	%let a=0;
	%let b=10;
	%put;
	%put (iii) Check, for randomly generated integers, that the results are uniformly distributed within respective the range [&a,&b];
	%ranuni(&dsn, &sampsize, a=&a, b=&b, int=yes);
	/* the integers are uniformly distributed within their respective ranges */
	PROC FREQ data=&dsn;
		tables n / chisq;
	run;

	%put;

	%work_clean(&dsn);
%mend _example_ranuni;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ranuni;
*/
