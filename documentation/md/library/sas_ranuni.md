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
