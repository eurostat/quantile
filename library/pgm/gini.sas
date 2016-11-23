/** 
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
*/ /** \cond */

%macro gini(dsn					/* Name of the input dataset 								(REQ) */
			, x					/* Variable on which the Gini index is computed 			(REQ) */
			, _gini_=			/* Name of the output macro variable storing the Gini index (REQ) */
			, wght=1			/* Weight/frequency defined as a variable OR a constant 	(OPT) */
			, method=canonical	/* Method used to compute the Gini index 					(OPT) */
			, lib=				/* Input library 											(OPT) */		
			);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_gini_) EQ 1, mac=&_mac,		
			txt=!!! Output macro variable _GINI_ not set !!!) %then
		%goto exit;

	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input dataset %upcase(&dsn) not found !!!)) %then
		%goto exit;

	/* check that the method is accepted */
	%local METHODS 	/* dummy selection */
		SEP			/* arbitrary separator */	
		ans;		/* temporary test variable */
	%let SEP=%str( );
	%let METHODS=canonical; /* list of possible methods for GINI calculation */

	%if %macro_isblank(method) %then %do;
		%let method=canonical;
	%if %error_handle(ErrorInputParameter, 
			%list_find(&METHODS, &method, sep=&SEP) EQ, mac=&_mac,		
			txt=%quote(!!! Input parameter %upcase(&method) not defined as a Gini estimation method !!!)) %then
		%goto exit;
		 	
	/* check that the variables used in the calculation exist */
	%ds_isempty(&dsn, var=&x, _ans_=ans, lib=&lib);
	%if %macro_isblank(ans) or &ans=1
		/* %error_handle(ErrorInputParameter, 
			%macro_isblank(ans) or &_ans=1,		
			txt=!!! Variable %upcase(&x) does not exist (or is empty) in dataset &idsn !!!) */ %then
		%goto exit;

	%if %datatyp(&wght)^=NUMERIC %then %do; 
		%ds_isempty(&dsn, var=&wght, _ans_=ans, lib=&lib);
		/* note that ds_isempty also checks that the variable exists (if it does not, it returns
		* an empty variable _ans) */
		%if %macro_isblank(ans) or &ans=1 %then
			%goto exit;
	%end;

	/* check that indeed some variables were passed for sorting */

	%if &method=canonical %then %do;
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
	%end;
	/* %else %do: implement other methods here */

	%exit:
%mend gini;

%macro _example_gini;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	data gini0;
		p="A"; x=1; output;
		p="B"; x=1; output;
		p="C"; x=1; output;
		p="D"; x=1; output;
		p="E"; x=1; output;
		p="F"; x=1; output;
		p="G"; x=1; output;
	run;

	data gini71_1;
		p="A"; x=1; output;
		p="B"; x=1; output;
		p="C"; x=1; output;
		p="D"; x=1; output;
		p="E"; x=1; output;
		p="F"; x=1; output;
		p="G"; x=1; output;
		p="H"; x=10; output;
		p="I"; x=33; output;
		p="J"; x=50; output;
	run;

	data gini71_2;
		p="A"; x=1;  w=7; output;
		p="B"; x=10; w=1; output;
		p="C"; x=33; w=1; output;
		p="D"; x=50; w=1; output;
	run;

	data gini21_1;
		p="A"; x=5; output;
		p="B"; x=5; output;
		p="C"; x=5; output;
		p="D"; x=10; output;
		p="E"; x=10; output;
		p="F"; x=10; output;
		p="G"; x=10; output;
		p="H"; x=15; output;
		p="I"; x=15; output;
		p="J"; x=15; output;
	run;

	data gini21_2;
		p="A"; x=5; w=3; output;
		p="B"; x=10; w=4; output;
		p="C"; x=15; w=3; output;
	run;

	data gini10;
		p="A"; x=2; w=3; output;
		p="C"; x=3; w=2; output;
	run;

	%local gini ogini;

	%put (i) Dummy test: default values do not exist in dataset;
	%let method=Marinastyle;
	%gini(gini0, x, _gini_=gini, method=&method);
	%if %macro_isblank(gini) %then 		%put OK: TEST PASSED - Method %upcase(&method) recognised as wrong method;
	%else 								%put ERROR: TEST FAILED - Method %upcase(&method) NOT recognised as wrong method;

	%put (ii) Test Gini index of uniform distribution: gini0;
	%gini(gini0, x, _gini_=gini);
	%let ogini=0;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for uniform gini0 dataset;
	%else 						%put ERROR: TEST FAILED - Wrong Gini index &gini returned for uniform gini0 dataset;

	%put (iii) Test Gini index of another distribution: gini71_1, no weight;
	%gini(gini71_1, x, _gini_=gini);
	%let ogini=71;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini71_1 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini71_1 datase;

	%put (iv) Test Gini index of same distribution: gini71_2, with weight;
	%gini(gini71_2, x, wght=w, _gini_=gini);
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini71_2 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini71_2 datase;

	%put (v) Test Gini index of another distribution: gini21_1, no weight;
	%gini(gini21_1, x, _gini_=gini);
	%let ogini=21;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini21_1 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini21_1 datase;

	%put (vi) Test Gini index of same distribution: gini21_2, with weight;
	%gini(gini21_2, x, wght=w, _gini_=gini);
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini21_2 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini21_2 datase;

	%put (vii) Test Gini index of another distribution: gini10, with weight;
	%gini(gini10, x, wght=w, _gini_=gini);
	%let ogini=10;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini10 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini10 datase;

	%put;
	
	%work_clean(gini0);	
	%work_clean(gini10);	
	%work_clean(gini71_1);	
	%work_clean(gini71_2);	
	%work_clean(gini21_1);	
	%work_clean(gini21_2);	
%mend _example_gini;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_gini; 
*/

/** \endcond */
