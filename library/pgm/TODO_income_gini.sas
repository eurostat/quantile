/** \cond */
/** 
## income_gini {#sas_income_gini}
Sort the observations in a given dataset.

	%income_gini(idsn, odsn, income=, pweight=, dropall=, method=, ilib=WORK, olib=WORK, debug=no);

### Arguments
* `idsn` : a dataset reference;
* `odsn` : name of the output dataset (in `WORK` library); when not set, the input
	dataset `idsn` is replaced with the newly sorted version; default: not set;
* `income` : (_option_) ; default: when not passed, `pwght` is set to either `&G_PING_EQINC` if it exists, 
	or `EQ_INC20`;;
* `pweight` : (_option_) personal weight; default: when not passed, `pweight` is set to either 
	`&G_PING_PWEIGHT` if it exists, or the personal _"adjusted cross sectional weight"_ `RB050a` otherwise;
* `dropall` : (_option_) boolean flag (`yes/no`);
* `method` : (_option_) ; default: _canonical_, hence the formula used for computing the Gini coefficient is:

	gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1)

* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` is used.
  
### Returns
In either `odsn` or `idsn` (updated when the latter is not passed), the original dataset sorted by
(ascending) `asc` variables and descending `desc` variables.

### Examples

Run macro `%%_example_income_gini` for examples.

### Note
Currently, only the `canonical` method is implemented. In short, this means that the macro `%%income_gini` 
runs the following `DATA` step:

	DATA &olib..&odsn;
		SET &ilib..&idsn end=last;
		retain swt swtvar swt2var swtvarcw ss 0;
		ss + 1;
		swt + &pwght;
		swtvar + &pwght * &income;
		swt2var + &pwght * &pwght * &income;
		swtvarcw + swt * &pwght * &income;
		if last then
		do;
			gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
		    output;
		end;
	run;

### See also
[%gini_index](@ref sas_gini_index).
*/ /** \cond */

%macro income_gini(/*input*/  idsn, 
			   	   /*output*/ odsn, 
			   	   /*option*/ income=, pweight=, dropall=yes, method=canonical, ilib=, olib=, debug=no);

	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%if %macro_isblank(olib) %then 	%let olib=&ilib;

	%put idsn=&idsn ilib=&ilib;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1,		
			txt=!!! Input dataset &idsn not found !!!) %then
		%goto exit;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 1,		
			txt=! Output dataset &odsn already exists !, verb=warn) %then
		%goto warning;
	%warning: /* nothing in fact: just proceed... */

	/* set the default variables when not passed as arguments */
	%if %macro_isblank(income) %then %do;
		%if %symexist(G_PING_EQINC) %then 	%let income=&G_PING_EQINC; 
		%else							%let income=EQ_INC20; 	
	%end;
 
	%if %macro_isblank(pweight) %then %do;
		%if %symexist(G_PING_PWEIGHT) %then 	%let pweight=&G_PING_PWEIGHT; 
		%else							%let pweight=RB050a; 	
	%end;

	/* check that the method is accepted */
	%local METHODS SEP;
	%let SEP=%str( );
	%let METHODS=canonical; /* list of possible methods for GINI calculation */
	%if not %macro_isblank(method) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%list_find(&METHODS, &method, sep=&SEP) EQ ,		
				txt=!!! Input parameter %upcase(&method) not defined as a GINI calculation method !!!) %then
			%goto exit;
	%end;
	%else
		%let method=canonical;
		 	
	/* check that the variables used in the calculation */
	%local _ans;
	%ds_isempty(&idsn, &pweight, _ans_=_ans);
	/* note that ds_isempty also checks that the variable exists (if it does not, it returns
	* an empty variable _ans */
	%if %macro_isblank(_ans) or &_ans=1
		/* %error_handle(ErrorInputParameter, 
			%macro_isblank(_ans) or &_ans=1,		
			txt=!!! Variable %upcase(&pweight) does not exist (or is empty) in dataset &idsn !!!) */ %then
		%goto exit;
	%ds_isempty(&idsn, &income, _ans_=_ans);
	%if %macro_isblank(_ans) or &_ans=1
		/* %error_handle(ErrorInputParameter, 
			%macro_isblank(_ans) or &_ans=1,		
			txt=!!! Variable %upcase(&income) does not exist (or is empty) in dataset &idsn !!!) */ %then
		%goto exit;

	/* check that indeed some variables were passed for sorting */

	%if &method=canonical %then %do;
		DATA &olib..&odsn
			%if &dropall=yes %then %do;
			(drop=swt swtvar swt2var swtvarcw ss)
			%end;
			;
			SET &ilib..&idsn end=last;
			retain swt swtvar swt2var swtvarcw ss 0;
			ss + 1;
			swt + &pwght;
			swtvar + &pwght * &income;
			swt2var + &pwght * &pwght * &income;
			swtvarcw + swt * &pwght * &income;
			if last then
			do;
				gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
			    output;
			end;
		run;
	%end;
	/* %else %do: implement other methods here */

	%exit:
%mend income_gini;

%macro _example_income_gini;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn ans method;
	%let dsn=TMP%upcase(&sysmacroname);
		
	%_dstest5;

	%put (i) Dummy test: default values do not exist in dataset;
	%let method=Marinastyle;
	%income_gini(_dstest5, &dsn, method=&method);
	%if %ds_check(&dsn)=0 %then 	%put ERROR: TEST FAILED - Method %upcase(&method) NOT recognised as wrong method;
	%else 							%put OK: TEST PASSED - Method %upcase(&method) recognised as wrong method;

	%put (ii) Dummy test: default values do not exist in dataset;
	%income_gini(_dstest5, &dsn);
	%if %ds_check(&dsn)=0 %then 	%put ERROR: TEST FAILED - Wrong output for _dstest5;
	%else 							%put OK: TEST PASSED - Nothing computed for _dstest5;
				
	%work_clean(&dsn);
	%work_clean(_dstest5);
%mend _example_income_gini;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;*/
%_example_income_gini; 


/** \endcond */
