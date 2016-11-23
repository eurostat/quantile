/** 
## var_dummy {#sas_var_dummy}
Create dummy variables in a dataset, _i.e._ variables with labels used to describe 
membership in a category with binary coding.

   %var_dummy(idsn, var, odsn=, prefix=, base=, format=, fullrank=yes, ilib=, olib=);

### Arguments
* `idsn` : a dataset reference;
* `odsn` : (_option_) name of the output dataset; 
* `prefix` : (_option_) prefix(s) used to create the names of dummy variables; the
	default is 'D_'; you can give one or more strings, in an order corresponding to the 
	`var` variables; note that `prefix=_VARNAME_`, which will use the name of the
	corresponding variable followed by an underscore, or `prefix=_BLANK_`, which will make 
	the prefix a null string (similar to specifying a null string in the macro argument) 
	are also accepted; 
* `name` : (_option_) if `name=_VAL_`, the dummy variables are named by appending the value 
	of the `var` variables to the prefix, otherwise, the dummy variables are named by 
	appending numbers, 1, 2, ... to the prefix; note that the resulting name must be 8 
	characters or less.; default: `name=_VAL_`;
* `base` :(_option_) indicates the level of the baseline category, which is given values 
	of 0 on all the dummy variables; you can give one or more strings, in an order 
	corresponding to the `var` variables; parameters `base=_FIRST_` or `base=_LOW_` specify
	that the lowest value of the VAR= variable is the baseline group; `base=_LAST_` or 
	`base=_HIGH_` specify the highest value of the variable; otherwise, you can specify 
	`base=<value>` to make a different value the baseline group; for a character variable, 
	you must enclose the value in quotes, _e.g._, `base=`'M'; 
* `format` : (_option_) user formats may be used for two purposes:  
		+ to name the dummy variables, and 
		+ to create dummy variables which are indicators for ranges of the input variable; 
	variables using the format option must be listed first in the`var` list.
* `fullrank` : (_option_) boolean flag (`yes/no`), set to `yes` to indicate that the indicator 
	for the `base` category is eliminated;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also 
	used.

### Returns
if not specified, the new
           variables are appended to the input dataset
 
### Examples
With the input data set:
 y | group | sex
:-:|:------|:----
10 |   A   |  M 
12 |   A   |  F 
13 |   A   |  M  
18 |   B   |  M 
19 |   B   |  M 
16 |   C   |  F 
21 |   C   |  M 
19 |   C   |  F  
the macro statement:

	%var_dummy(test, group) ;

produces two new variables, `D_A` and `D_B` in the table `test`:  
 y | group | sex | D_A | D_B
:-:|:------|:----|----:|-----:			
10 |   A   |  M  |  1  |   0
12 |   A   |  F  |  1  |   0
13 |   A   |  M  |  1  |   0
18 |   B   |  M  |  0  |   1
19 |   B   |  M  |  0  |   1
16 |   C   |  F  |  0  |   0
21 |   C   |  M  |  0  |   0
19 |   C   |  F  |  0  |   0
since group `C` is the baseline category (corresponding to `base=_LAST_`). With the input dataset:

  * proc format;
    *  value $sex 'M'='Male' 'F'='Female';
   %var_dummy(test, var =sex group, format=$sex, prefix=_BLANK_ _VARNAME_) ;

 produces a dummy for `sex` named FEMALE, and two dummies for `group`:
 y | group | sex | FEMALE | GROUP_A | GROUP_B
:-:|:------|:----|-------:|--------:|---------:			
10 |   A   |  M  |   0    |    1    |    0
12 |   A   |  F  |   1    |    1    |    0
13 |   A   |  M  |   0    |    1    |    0
18 |   B   |  M  |   0    |    1    |    1
19 |   B   |  M  |   0    |    1    |    1
16 |   C   |  F  |   1    |    1    |    0
21 |   C   |  M  |   0    |    1    |    0
19 |   C   |  F  |   1    |    1    |    0

### Notes
1. **The macro `%%var_dummy` is  a wrapper to M. Friendly's original `%%dummy` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html>. See 
resources available at [DataVis.ca](http://www.datavis.ca/sasmac/).
2. Given a character or discrete numerical variable, the `%%var_dummy` macro creates
dummy (0/1) variables to represent the levels of the original variable.  If the original 
variable has `c` levels, then `(c-1)` new variables are produced (or `c` variables, if 
`fullrank=yes`).

 When the original variable is missing, all dummy variables will be 
 missing (V7+ only).


http://www.math.yorku.ca/SCS/sasmac/dummy.html

### See also
[DUMMY](http://www.datavis.ca/sas/vcd/macros/dummy.sas).
=*/
 
%macro var_dummy(idsn    		/* Name of input dataset                  				(REQ) */
    			, var        	/* Variable(s) to be dummied              				(REQ) */
  				, odsn=       	/* Name of output dataset                 				(OPT) */
   				, base=_last_  	/* Name of the base category                          	(OPT) */
   				, prefix = D_,	/* Prefix for dummy variable names        				(OPT) */
   				, format =,     /* format used to categorize variable     				(OPT) */
   				, name  = VAL,  /* Flag set for dummy variables' names    				(OPT) */
   				, fullrank=yes  /* Boolean flag set for eliminatinig baseline category	(OPT) */
				, ilib=			/* Name of the input library 											(OPT) */
				, olib=			/* Name of the output library 											(OPT) */
   				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* check  the input dataset */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) 
		or 
		%error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=!!! Input parameter VAR needs to be set !!!) %then
		%goto exit;

	/* %if %upcase(&idsn) = _LAST_ %then %let idsn = &syslast;
		%if %error_handle(ErrorInputDataset, 
				%upcase(&idsn) EQ _NULL_, mac=&_mac,		
				txt=!!! Missing default input dataset (_LAST_ is _NULL_) !!!) %then
			%goto exit;
	 */

	/* set the default output dataset */
	%if %macro_isblank(olib) %then 	%let olib=WORK/*&ilib*/;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists: will be replaced!, 
			verb=warn) %then
		%goto warning1;
	%warning1:

	/*  initialize output dataset */
	%if %macro_isblank(odsn) %then %do;
		DATA &olib..&out;
			SET &ilib..&idsn;
	%end;

	%let base = %upcase(&base);
	%let name = %upcase(&name);
	%let prefix = %upcase(&prefix);

	/* j indexes variables, vari is the current variable name */
	%local j 
		vari;
	%let j=1;
	/* find the current variable name */
	%let vari= %scan(&var,    &j, %str( ));

	/* loop over variables */
	%do %while(&vari ^= );

		/* find the current prefix for dummies */
		%let pre = %scan(&prefix, &j, %str( ));
		%if &pre = VARNAME | &pre = %then %let pre=&vari._;
		/* keyword BLANK for prefix indicates no prefix */
		%if &pre=BLANK %then %let pre=;

		/* find the current base for dummies */
		%let baseval = %scan(&base, &j, %str( ));
		%if &baseval = %then %let baseval=_LAST_;

		/* find the current format for dummies */
		%let fmt = %scan(&format, &j, %str( ));

		/* determine values of variable to be dummied */
		PROC SUMMARY  data = &out nway ;
	     	CLASS &vari ;
	     	%if %length(&fmt) GT 0 %then %do;
		  		/* make sure format name includes a '.' */
	        	%if "%substr(&fmt, %length(&fmt))" ne "." %then 
					%let fmt = &fmt..;
	        		FORMAT &vari &fmt;
	     		%end;
	     		output out = _cats_ ( keep = &vari ) ;
				%if &syserr > 4 %then %goto exit;

				%if &fullrank %then %do;
				/* eliminate the base category */
				DATA _cats_;
					SET _cats_ end=_eof_;
					%if &baseval = _FIRST_ | &baseval = _LOW_ 
						%then %str( if _n_ = 1 then delete;);
					%else %if &baseval = _LAST_ | &baseval = _HIGH_
						%then %str( if _eof_ then delete;);
					%else %str(if &vari = &baseval then delete;);
				run;
		%end;

		DATA _null_ ;
	 		SET _cats_ nobs = numvals ;
	 		if _n_ = 1 then do;
				/* if there are no non-baseline values - abort macro */ 
				call symput('abort',trim( left( put( (numvals=0), best. ) ) ) ) ;
				/* place number of dummies into macro variable num */
				call symput( 'num', trim( left( put( numvals, best. ) ) ) ) ;
			end;

			/* number the values, place in macro variables c## */ 
			%if %length(&fmt) gt 0 %then %do;
				call symput ( 'c' || trim ( left ( put ( _n_,     best. ) ) ),
										trim(left(put(&vari,&fmt)) ) );
			%end;
			%else %do;
				call symput ( 'c' || trim ( left ( put ( _n_,     best. ) ) ),
										trim ( left ( &vari ) ) ) ;
			%end;
		run ;
		%if &syserr > 4 %then %goto exit;

		/* create list of dummy variables for the j-th input variable */

		%if "&name" = "_VAL_" %then %do ;
			/*  names by variable value */
			%let vl&j =; 
			%do k=1 %to &num;
				%if %error_handle(ErrorInputParameter, 
						&sysver LT 7 & %length(&pre&&c&k) GT 8, mac=&_mac,		
						txt=!!! Cannot generate names longer than 8 characters !!!) %then
					%goto exit;
				%let vl&j = &&vl&j  &pre&&c&k;
				%end; ;

			DATA &olib..&odsn;
				SET &olib..&odsn;
				array __d ( &num ) 
				%do k=1 %to &num ;	
					&pre&&c&k
				%end; 
				;
				/* DUMMY: Creating dummy variables &pre&&c1 .. &pre&&c&num for &vari */

		%end;
		%else %do;
			/* numeric suffix names */
			%let vl&j =; 
			%do k=1 %to &num; 
				%if %error_handle(ErrorInputParameter, 
						&sysver LT 7 & %length(&pre.&k) GT 8, mac=&_mac,		
						txt=!!! Cannot generate names longer than 8 characters !!!) %then
					%goto next;
				%let vl&j = &&vl&j  &pre.&k;
			%end; ;
		run;
	
	/* assign values to the dummy variables for the j-th input variable */
	DATA &olib..&odsn( rename = ( 
		%do k=1 %to &num ;
			d&k = &pre.&k
		%end; 
		));
		SET &olib..&odsn;
		/* DUMMY: Creating dummy variables &pre.1 .. &pre.&num */
		array __d ( &num ) d1-d&num ;
	%end;

	%if &sysver >= 7 %then %do;
     	if missing(&vari) then do;
	  	 	do j=1 to &num;
        		__d(j)=.;
		  	end;
			return;
     	end;
	%end;

	/* assign values to dummy variables */
	drop j;
	do j = 1 to &num ; /* initialize to 0 */
		__d(j) = 0 ;
	end ;


	%if %length(&fmt) eq 0 %then %do;
     	/* case 1:  No format */
        if &vari = "&c1" then __d ( 1 ) = 1 ;  /* create dummies */
        %do i = 2 %to &num;       
         	else if &vari="&&c&i" then __d ( &i ) = 1 ;
        %end;
     %end;
     %else %do;
     	/* case 2:  with format */
        if put(&vari,&fmt) = "&c1" then __d ( 1 ) = 1;
        %do i = 2 %to &num ;       
           	else if put(&vari,&fmt)="&&c&i" then __d ( &i ) = 1;
        %end;
     %end;
	run;

	/* find the next variable */

	%let j=%eval(&j+1);
	%let vari = %scan(&var, &j, %str( ));

	/* end of loop(&i): vari = &vari  pre=&pre; */
	%next:
	%end;  /* %do %while */

	%exit:

%mend var_dummy;
