/**
## par_check {#sas_par_check}
Perform simple logical/acceptance test on a given NUMERIC or CHAR (list of) parameter(s).

	%let ans=%par_check(par, type=, range=, norange=, set=, noset=, casense=no);

### Arguments
* `par` : (list of) parameter(s) to test; can be either of NUMERIC or CHAR type;
* `type` : (_option_) flag set to check whether the input parameter is `NUMERIC`, `INTEGER` or `CHAR`; 
	in the case `type=INTEGER`, and `par` is actually `NUMERIC`, it is further tested whether `par` is 
	an integer or not; default: empty, _i.e._ the type of `par` is not tested;
* `range` : (_option_) range of acceptance values for the input parameter; this is a list of length <=2 
	of the form `min max` representing the minimum and maximum values of the range `]min, max[` to be 
	tested against `par` in the case it is `NUMERIC`; in the case the length of `range` is 1, then only
	the minimum value is tested, _i.e._ it is regarded as `range=min`; this option is incompatible with
	`type` when `type` is set to `CHAR`; default: empty, _i.e._ no range is tested;
* `norange` : (_option_) ibid for the exlusion range for the input parameter, _i.e._ the range `]min, max[`
	of values to which `par` should not belong; in the case the length of `range` is 1, then only the 
	maximum value is tested, _i.e._ it is regarded as `norange=max` default: empty, _i.e._ no range is 
	tested;
* `set` : (_option_) list supporting the set of acceptance values for the input parameter which will
	be tested against all the values in it; default: empty, _i.e._ no values are tested;
* `noset` : (_option_) ibid for the list of exluded values for the input parameter; default: empty, _i.e._ 
	no values are tested;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive checking when the input
	parameter tested is CHAR; default: `casense=no`, _i.e._ the checking does not take into account the
	cases.

### Returns
`ans` : (list of) error codes of the test (hence of same length as `par`) where for each item in `par`
the corresponding item in `ans` is set to:
		+ `0` if the item verifies all the conditions expressed by `type`, `range`, `norange`, `set`, 
			and/or `noset`,
    	+ `1` if the item does not verify the conditions on `type` and/or (in the case `par` is of
			`NUMERIC` type and `type=INTEGER` is tested) it is also an integer, 
		+ `2` if the item does not verify the value conditions on `noset` (_e.g._, `par` is `NUMERIC`
			and is listed in `noset`),
		+ `3` if the item does not verify the conditions on `range` and/or `norange` (_e.g._, `par` is 
			`NUMERIC` and does not lie in the range `range`).

### Examples
Simples checks can be ran over NUMERIC parameters, for instance we can test whether a parameter is a 
strictly positive or negative integer, _e.g._:

	%let ans=%par_check(1, type=INTEGER, range=0);
	%let ans=%par_check(-1, type=INTEGER, norange=0);

will both return `ans=0`. More practically, we can also test whether a given parameter `par` is within 
the range ]0,10[, _e.g._ using:

	%let par=9.5;
	%let ans=%par_check(&par, range=0 10);

then we will have `ans=2`; we may also want to test whether that same parameter is in the range `[0 10]` 
(_i.e._ including the bounds) using:

	%let ans=%par_check(&par, range=0 10, set=0 10);

which returns `ans=0`; finally, we can test whether it is an integer:

	%let ans=%par_check(&par, type=INTEGER, range=0 10, set=0 10);

which will return `ans=1` this time. To test whether it is a positive or nul value, we can simply run:

	%let ans=%par_check(&par, type=NUMERIC, range=0, set=0);

which aims in fact at testing whether `par` is in the range `]0,+inf[` or equal to `{0}`, and returns 
`ans=0`. It is then possible to test several parameters together, _e.g._:

	%let par=1 a 10 9.5 2;
	%let ans=%par_check(&par, type=INTEGER, range=0 10);

which returns `ans=0 1 2 1 0` since it checks the items in the list `par` are integers in the range 
]0,0[. As for CHAR parameters, the test consists simply in checking the inclusion of the `par` string 
into the set formed by `set`, _e.g._:

	%let par=at;
	%let ans=%par_check(&par, type=CHAR, set=DE FR AT SE);

will return `ans=0` (since `casense=no` by default).

Run `%%_example_par_check` for more examples.

### Notes
1. As in the examples above, whenever you want to test whether a NUMERIC value is an Integer in a closed 
range `[&a,&b]`, you shall run:

    %let ans=%par_check(&par, type=INTEGER, range=&a &b, set=&a &b);
so as to test in practice whether it is in the union: `]&a,&b[ U {&a,&b}`. Note that the order in `set`
does not matter, _i.e._ `set=&b &a` is also accepted.
2. More generally, for NUMERIC parameters `par`, the following command:

       %let ans=%par_check(&par, type=INTEGER, range=&a &b, set=&c, norange=&x &y, noset=&z);
tests whether `par` is in the set represented by `(]&a,&b[ U {&c}) \ (]&x,&y[ U {&z})`.

### Reference
Wilson, S.A. (2011): ["The validator: A macro to validate parameters"](http://support.sas.com/resources/papers/proceedings11/015-2011.pdf).

### See also
[%macro_isblank](@ref sas_macro_isblank).
*/
/** \cond */ 

%macro par_check(par			/* Input parameter to check 			(REQ) */
				, type=			/* Type of input parameter to check 	(OPT) */
				, range=		/* Range of inclusion values to check 	(OPT) */
				, norange=		/* Range of exclusion values to check 	(OPT) */
				, set=			/* Set of inclusion values to check 	(OPT) */
				, noset=		/* Set of exclusion values to check 	(OPT) */
				, casense=no	/* Flag for case sentivity			 	(OPT) */
				);	
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _ans;
	%let _ans=; 

	%local _type 
		_k 
		_par 
		SEP 
		_len 
		_isint;
	%let _isint=NO;
	%let SEP=%str( );

	/* check the existence/setting of the input parameters */
	%if %error_handle(ErrorInputParameter, 
				%macro_isblank(type) EQ 1 and %macro_isblank(set) EQ 1 and %macro_isblank(range) EQ 1
				and %macro_isblank(noset) EQ 1 and %macro_isblank(norange) EQ 1, mac=&_mac,
				txt=%quote(!!! Missing input parameters - One among TYPE, SET, NOSET, RANGE, or NORANGE should be set !!!))
			or 
			%error_handle(ErrorInputParameter, 
				%macro_isblank(par) EQ 1, mac=&_mac,
				txt=!!! Missing input parameters PAR !!!) 
			or
			%error_handle(ErrorInputParameter, 
				%upcase(&casense)^=YES and %upcase(&casense)^=NO, mac=&_mac,	
				txt=!!! Parameter CASESENS is boolean flag with values in (yes/no) !!!) %then 
		%goto exit;

	/* check the formatting of the input parameters */
	%if not %macro_isblank(type) %then %do;
		%if %error_handle(ErrorInputParameter, 
				"&type"^="CHAR" and "&type"^="NUMERIC" and "&type"^="INTEGER", mac=&_mac,		
				txt=%quote(!!! Parameter TYPE should be either NUMERIC, INTEGER or CHAR !!!)) %then
			%goto exit;
		%else %if "&type"="CHAR" %then %do;
			%if %error_handle(ErrorInputParameter, 
					%macro_isblank(range) EQ 0, mac=&_mac,		
					txt=!!! Incompatible parameter RANGE with TYPE when tested type is CHAR !!!) %then
				%goto exit;
		%end;
		%else %if "&type"="INTEGER" %then %do;
			%let type=NUMERIC;
			%let _isint=YES;
		%end;
	%end;

	%if %upcase(&casense)=NO %then %do;
		%if not %macro_isblank(set) %then 		%let set=%upcase(&set);
		%if not %macro_isblank(noset) %then 	%let noset=%upcase(&noset);
	%end;

	%if not %macro_isblank(range) /* and &_type = NUMERIC */ %then %do;
		%let _len=%sysfunc(countw(&range, &SEP));
		/* note that at this stage, _type is necessarily NUMERIC */
		%if %error_handle(ErrorInputParameter, 
				&_len LT 1, mac=&_mac,		
				txt=!!! Parameter RANGE should be of length 1 at least for testing NUMERIC parameter !!!) %then
			%goto exit;
		/* set the min max values once for all */
		%local min max;
		%let min=%scan(&range, 1, &SEP);
		%if &_len GT 1 %then	%let max=%scan(&range, 2, &SEP);
	%end;

	%if not %macro_isblank(norange) %then %do;
		%let _len=%sysfunc(countw(&norange, &SEP));
		%if %error_handle(ErrorInputParameter, 
				&_len LT 1, mac=&_mac,		
				txt=!!! Parameter NORANGE should be of length 1 at least for testing NUMERIC parameter !!!) %then
			%goto exit;
		/* set the min max values once for all */
		%local nomin nomax;
		%let nomin=%scan(&norange, 1, &SEP);
		%if &_len GT 1 %then	%let nomax=%scan(&norange, 2, &SEP);
	%end;

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	%local WrongTypeError 
		WrongValuesError 
		WrongRangeError;
	%let WrongTypeError=1;
	%let WrongValuesError=2;
	%let WrongRangeError=3;

	/* start the actual checking loop */
	%do _k=1 %to %sysfunc(countw(&par, &SEP));
		%let _par=%scan(&par, &_k, &SEP);
		%let _type=%datatyp(&_par);

		/* test the type */
		%if not %macro_isblank(type) %then %do;
			%if "&_type" NE "&type" %then %do;
				%let _ans=&_ans.&SEP.&WrongTypeError;
				%goto next;
			%end;
			%else %if "&_type"="NUMERIC" and &_isint=YES %then %do;
				%if &_par NE %sysfunc(floor(&_par)) %then %do;
					%let _ans=&_ans.&SEP.&WrongTypeError;
					%goto next;
				%end;
			%end;
		%end;

		%if "&_type"="CHAR" and %upcase(&casense)=NO %then %do;
			%let _par=%upcase(&_par);
		%end;

		/* ibid with the set of excluded values */
		%if not %macro_isblank(noset) %then %do;
			%if %sysfunc(find(&set, &_par)) > 0 %then %do;	
				%let _ans=&_ans.&SEP.&WrongValuesError; /* value found => error */
				%goto next;
			%end;
		%end;

		/* test the set of possible values */
		%if not %macro_isblank(set) %then %do;
			/* check whether _par corresponds to any of the considered values */
			%if %sysfunc(find(&set, &_par)) > 0 %then 
				%let _ans=&_ans.&SEP.0; /* value found => accepted */
			%else %if "&_type"="CHAR" %then /* we did not find the char ... */
				%let _ans=&_ans.&SEP.&WrongValuesError;	
			%goto next;
			/* note that we test _par against set prior to test the exclusion range */
		%end;

		%if "&_type"="CHAR" %then %do;
			%if %macro_isblank(range) and %macro_isblank(norange) %then
				%let _ans=&_ans.&SEP.0;	/* we are ok... */
			%else	/* obviously we test whether it is numeric */
				%let _ans=&_ans.&SEP.&WrongTypeError;	
			%goto next; /* no further test */
		%end;

		/* test the range of values
		 * note that at this stage, _type is necessarily NUMERIC */
		%if not %macro_isblank(range) /* and &_type = NUMERIC */ %then %do;
			/* test the minimum accepted value */
			%if %sysevalf(&_par <= &min) %then %do;
				%let _ans=&_ans.&SEP.&WrongRangeError;
				%goto next;
			%end;
			%if not %macro_isblank(max) %then %do;
				/* test the maximum accepted value, when passed */
				%if %sysevalf(&_par >= &max) %then %do;
					%let _ans=&_ans.&SEP.&WrongRangeError;
					%goto next;
				%end;
			%end;
		%end;

		/* ibid with the exclusion range */
		%if not %macro_isblank(norange) /* and &_type = NUMERIC */ %then %do;
			%if %macro_isblank(nomax) %then %do;
				%if %sysevalf(&_par >= &nomin) %then %do;
					%let _ans=&_ans.&SEP.&WrongRangeError;
					%goto next;
				%end;
				/* %else: do nothing */
			%end;
			%else %if %sysevalf(&_par >= &nomin) and %sysevalf(&_par <= &nomax) %then %do;
				%let _ans=&_ans.&SEP.&WrongRangeError;
				%goto next;
			%end;
		%end;
	
		/* if we arrive here, no error met so far! */
		%let _ans=&_ans.&SEP.0;
		%next:
	%end;

	%exit:
	&_ans
%mend par_check;

%macro _example_par_check;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let par=1;
	%put;
	%put (o) A dummy test with missing arguments;
	%if %macro_isblank(%par_check(&par)) %then 	%put OK: TEST PASSED - Dummy test return empty output;
	%else										%put ERROR: TEST FAILED - Non empty output returned;

	%local par oans;

	%let par=;
	%put;
	%put (i) A dummy test with type CHAR and range parameter together;
	%if %macro_isblank(%par_check(&par, type=CHAR)) %then 	%put OK: TEST PASSED - Dummy test return empty output;
	%else													%put ERROR: TEST FAILED - Non empty output returned;

	%let par=a;
	%put;
	%put (ii) A dummy test with type CHAR and range parameter together;
	%if %macro_isblank(%par_check(&par, type=CHAR, range=0 1)) %then 	
		%put OK: TEST PASSED - Dummy test on CHAR type fails;
	%else										
		%put ERROR: TEST FAILED - Dummy test not detected;

	%put;
	%put (iii) Test whether a CHAR value is of type NUMERIC;
	%if %par_check(&par, type=NUMERIC)=1 %then 	%put OK: TEST PASSED - Empty result for CHAR variable tested as NUMERIC;
	%else										%put ERROR: TEST FAILED - Type error not detected;

	%let par=0.5;
	%put;
	%put (iv) Test whether a NUMERIC value is of type CHAR;
	%if %par_check(&par, type=CHAR)=1 %then 	%put OK: TEST PASSED - Empty result for NUMERIC variable tested as CHAR;
	%else										%put ERROR: TEST FAILED - Type error not detected;

	%let par=1;
	%put;
	%put (v) Test whether par=&par is a strictly positive integer;
	%if %par_check(&par, type=INTEGER, range=0)=0 %then %put OK: TEST PASSED - Range/type test succeeds and returns 0;
	%else												%put ERROR: TEST FAILED - Range/type test fails;

	%put;
	%put (vi) Test whether it is a strictly negative integer;
	%if %par_check(&par, type=INTEGER, norange=0)=3 %then 	%put OK: TEST PASSED - Range/type test succeeds and returns 3;
	%else													%put ERROR: TEST FAILED - Range/type test fails;

	%let par=-1;
	%put;
	%put (vii) Test whether par=&par is a strictly negative integer;
	%if %par_check(&par, type=INTEGER, norange=0)=0 %then 	%put OK: TEST PASSED - Range/type test succeeds and returns 0;
	%else													%put ERROR: TEST FAILED - Range/type test fails;

	%put;
	%put (viii) Test whether it is a strictly positive integer;
	%if %par_check(&par, type=INTEGER, range=0)=3 %then 	%put OK: TEST PASSED - Range/type test succeeds and returns 3;
	%else													%put ERROR: TEST FAILED - Range/type test fails;

	%let par=0.5;
	%let range=-0.5 0.5;
	%put;
	%put (ix) Test whether the value &par is in range of range =]&range[;
	%if %par_check(&par, range=&range) EQ 3 %then 		%put OK: TEST PASSED - Range test fails and returns 3;
	%else												%put ERROR: TEST FAILED - Range test returns error;

	%put;
	%put (x) Same test with range of range ]&range];
	%if %par_check(&par, range=&range, set=0.5) EQ 0 %then 	%put OK: TEST PASSED - Range/value test succeeds and returns 0;
	%else													%put ERROR: TEST FAILED - Range test returns wrong error;

	%let par=45;
	%let range=0;
	%let value=0;
	%put;
	%put (xi) Test whether the value &par is a positive or nul integer, ie in range =]&range, +inf[ U {&value};
	%if %par_check(&par, type=INTEGER, range=&range, set=&value) EQ 0 %then 		
		%put OK: TEST PASSED - Range test succeeds and returns 0;
	%else												
		%put ERROR: TEST FAILED - Range test returns error;

	%let norange=40 50;
	%put;
	%put (xii) Test whether it is a positive or nul integer, at the exclusion of the range ]&norange[, ie in range =]&range, +inf[ U {&value} \ ]&norange[;
	%if %par_check(&par, type=INTEGER, range=&range, set=&value, norange=&norange) EQ 3 %then 		
		%put OK: TEST PASSED - Range test succeeds and returns 3;
	%else												
		%put ERROR: TEST FAILED - Range test returns error;

	%let par=4;
	%let range=0 5;
	%let value=9;
	%put;
	%put (xiii) Test whether the value &par is Integer in ]&range] U {&value};
	%if %par_check(&par, type=INTEGER, range=&range, set=&value) EQ 0 %then 	
		%put OK: TEST PASSED - Range/value test succeeds and returns 0;
	%else																
		%put ERROR: TEST FAILED - Range test returns error;

	%let par=9;
	%put;
	%put (xiv) Same test with value &par;
	%if %par_check(&par, type=INTEGER, range=&range, set=&value) EQ 0 %then 	
		%put OK: TEST PASSED - Range/value test succeeds and returns 0;
	%else															
		%put ERROR: TEST FAILED - Range test returns error;

	%let par=3.5;
	%put;
	%put (xv) Same test again with value &par;
	%if %par_check(&par, type=INTEGER, range=&range, set=&value) EQ 1 %then 	
		%put OK: TEST PASSED - Range/value test succeeds and returns 1;
	%else																
		%put ERROR: TEST FAILED - Range test returns error;

	%let par=4 9 3.5;
	%put;
	%put (xvi) Now perform the same test with parameters passed together in &par;
	%let oans=0 0 1;
	%if %par_check(&par, type=INTEGER, range=&range, set=&value) EQ &oans %then 	
		%put OK: TEST PASSED - Range/value test succeeds and returns &oans;
	%else																
		%put ERROR: TEST FAILED - Range test returns error;
	
	%let par=1 a 10 9.5 2 5;
	%let range=0 10;
	%put;
	%put (xvii) Another test for parameters: &par on the range ]&range[;
	%let oans=0 1 3 1 0 0;
	%if %par_check(&par, type=INTEGER, range=&range) EQ &oans %then 	
		%put OK: TEST PASSED - Range/value test succeeds and returns &oans;
	%else																
		%put ERROR: TEST FAILED - Range test returns error;
	
	%let par=1 a 10 9.5 2 5;
	%let values=10;
	%let norange=1 10;
	%put;
	%put (xviii) Another test for parameters: &par on the range ]&range] \ ]&norange[;
	%let oans=0 1 0 1 3 3;
	%if %par_check(&par, type=INTEGER, range=&range, set=&values, norange=&norange) EQ &oans %then 	
		%put OK: TEST PASSED - Range/value test succeeds and returns &oans;
	%else																
		%put ERROR: TEST FAILED - Range test returns error;

	%let par=ZZZ;
	%let value=a b zzz cc;
	%put;
	%put (xix) Test whether "&par" is any value in the list "&value";
	%if %par_check(&par, set=&value) EQ 0 %then %put OK: TEST PASSED - Value test succeeds: &par found in %upcase(&value);
	%else										%put ERROR: TEST FAILED - Value &par not found in %upcase(&value);

	%put;
	%put (xx) Same test, but adding case sentiviness (set to yes);
	%if %par_check(&par, set=&value, casense=yes) EQ 2 %then 	%put OK: TEST PASSED - Value test fails: &par not found in &value;
	%else														%put ERROR: TEST FAILED - Value &par not found in %upcase(&value);

%mend _example_par_check;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_par_check;
*/
