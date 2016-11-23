/**
## SAS {#sas_assignPercentile}
[//]: # (Divide a given sample, possibly weighted, into a certain number of slices of equal size, with units ranked according to a variable of interest.)

    %assignPercentile(idsn, var, weight, s, odsn =, name_s =, ilib = WORK, olib = WORK);

### Arguments
* `idsn`: the table which contains the variable of interest and possibly the weights
* `var`: the variable of interest (e.g. income or wealth). It has to be numeric;
* `s`: the number of slices;
* `weight`: (_option_) the variable containing the weights (e.g. in case of survey data). By default, weight is 1;
* `odsn` : (_option_) the name of the table that contains the output data. By default, this is the input table;
* `name_s`: (_option_) the name of the variable providing the slice number;
* `ilib`: (_option_) the library where the input table is stored. By default, the WORK library;
* `olib`: (_option_) the library where the output table has to be stored. By default, the WORK library.

### Returns
`odsn` : name of the final output dataset created, stored in the `olib` library. 

### Examples

Run macro `%%_example_assignPercentile` for examples.

### See also

*/

/** \cond */
%macro assignPercentile(idsn, var, s, weight =,odsn =, name_s =, ilib = WORK, olib = WORK) ;

	%if %macro_isblank(name_s) %then %let name_s = &var._s ;

	/* various checkings */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	%if %macro_isblank(odsn) %then %let odsn = &idsn ;

	%if %error_handle(WarningOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0 and &odsn ne &idsn,		
			txt=! Output dataset %upcase(&odsn) already exists !, 
			verb=warn) %then
		%goto warning;
	%warning: /* nothing in fact: just proceed... */

	%if %error_handle(ErrorInputParameter,
			%var_check(&idsn, &var, lib = &ilib) EQ 1,
			txt =!!! Variable %upcase(&var) does not exist in table &idsn !!! ) %then
	%goto exit ;

	%if %macro_isblank(weight) EQ 0 %then %do ;
		%if %error_handle(ErrorInputParameter,
				%var_check(&idsn, &weight, lib = &ilib) EQ 1,
				txt =!!! Variable %upcase(&weight) does not exist in table &idsn !!! ) %then
		%goto exit ;

	/* case weights with missing values */
		%global isMissing ;
		%ds_iscond(&idsn, missing(&weight), _ans_ = isMissing) ;
		%if %error_handle(ErrorInputDataset,
				&isMissing EQ 1,
				txt =!!! Weighting variable %upcase(&weight) contains missing values !!! ) %then
		%goto exit ;

	/* case weights with missing values */
		%global isNeg ;
		%ds_iscond(&idsn, &weight < 0, _ans_ = isNeg) ;
		%if %error_handle(ErrorInputDataset,
				&isNeg EQ 1,
				txt =!!! Weighting variable %upcase(&weight) has negative values !!! ) %then
		%goto exit ;
	%end ;

	proc sort data=&ilib..&idsn out=_temp_ ;
	by &var ;
	run ;

	%if %macro_isblank(weight) %then %do ;
		data _temp_ ;
		set _temp_ ;
		w = 1 ;
		run ;

		%let weight = w ;
	%end ;

	proc sql ;
	select sum(&weight) into: nb from _temp_ where &var is not missing ;
	quit ;

	data _temp_ ;
	set _temp_ ;
	retain n 0 ;
	if missing(&var) = 0 then do ;
		n = n + &weight ;
		ww = ceil((n/&nb)*&s) ;
	end ;
	else do ;
		n = n + 0 ;
		ww = . ;
	end ;
	run ;

	data &olib..&odsn ;
	set _temp_ ;
	&name_s = ww ;
	drop n ww
	%if %macro_isblank(weight) %then %do ;
	w 
	%end ;
	;
	run ;

	%exit:
%mend ;


%macro _example_assignPercentile ;

%_dstest1001 ;

%assignPercentile(_dstest1001, i, 10) ;
%assignPercentile(_dstest1001, i, 10, weight = strata, name_s = dec) ;

%mend ;

options mprint ;
%_example_assignPercentile ;

/** \endcond */