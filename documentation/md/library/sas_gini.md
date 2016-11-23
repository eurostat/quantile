## gini {#sas_gini}
Compute the Gini index of a set of observations. 

	%gini(dsn, var, wght=, _gini_=, method=, lib=WORK);

### Arguments
* `dsn` : a dataset reference with continuous observations;
* `var` : variable of the input dataset `dsn` on which the Gini index will be computed;
* `wght` : (_option_) weight (frequencies), either a variable in `dsn` to use to weight the values 
	of `var`, or a constant value; default: `wght=1`, _i.e._ it is not used;
* `method` : (_option_) method used to compute the Gini index; default: _canonical_, _i.e._ the 
	formula used for computing the Gini index (which is 100* Gini coefficient) as:

        gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1)
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
`_gini_` : name of the macro variable storing the value of the Gini index.

### Examples
Considering the following datasets `gini10_1`:
Obs| x
---|---
 A | 2 
 A | 2 
 A | 2 
 B | 3 
 B | 3 
and `gini10_2`;
Obs| x | w
---|---|---
 A | 2 | 3
 B | 3 | 2
both calls to the macro:

	%let gini=;
	%gini(gini10_1, x, _gini_=gini);
	%gini(gini10_2, x, wght=w, _gini_=gini);

actually return the Gini index: `gini=10`.

Run macro `%%_example_gini` for examples.

### Note
Currently, only the `canonical` method is implemented. In short, this means that the macro `%%gini` 
runs the following `DATA` step:

		DATA _null_;
			SET &lib..&dsn end=__last;
			retain swt swtvar swt2var swtvarcw ss 0;
			xwgh = &wght * &x;
			ss + 1;
			swt + &wght;
			swtvar + xwgh;
			swt2var + &wght * xwgh;
			swtvarcw + swt * xwgh;
			if __last then
			do;
				gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
				call symput("&_gini_",gini);
			end;
		run;

### See also
[%income_gini](@ref sas_income_gini).
