/**
## var_count {#sas_var_count}
Return the number of missing and non-missing values of a given variable in a dataset.

	%var_count(dsn, var, _count_=, _nmiss_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : a field name whose information is provided;
* `lib` : (_option_) output library; default: `lib` is set to `WORK`.

### Returns
`_count_, _nmiss_` : (_option_) names of the macro variables used to store the count or non-missing
	and missing values of the var variable in the dataset respectively; though both optional, one	
	at least should be passed.

### Examples
Let us consider the table `_dstest28`:
geo | value 
----|-------
 ' '|  1    
 AT |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  5 

then we can find the number of non-missing/missing `value` by running:

	%let count=;
	%let nmiss=;
	%var_count(_dstest28, value, _count_=count, _nmiss_=nmiss); 

which returns `count=4` and `nmiss=2`.

Run macro `%%_example_var_count` for more examples.

### See also
[%ds_count](@ref sas_ds_count), [%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info).
*/ /** \cond */

%macro var_count(dsn
				, var
				, _count_=
				, _nmiss_=
				, lib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_count_) EQ 1 and %macro_isblank(_nmiss_) EQ 1, mac=&_mac,		
			txt=!!! Missing parameters: _COUNT_ or _NMISS_ !!!) %then
		%goto exit;

 	%if %macro_isblank(lib) %then 	%let lib=WORK;
	
	%if %error_handle(ErrorInputParameter, 
			%var_check(&dsn, &var, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Field %upcase(&var) not found in dataset %upcase(&dsn) !!!) %then
		%goto exit;

	/*
		data _null_;
	   		dsid=open(&dsn,"i");
		   	num=attrn(dsid,"nvars");
		   	do while (fetch(dsid)=0);
		      	do i=1 to num;
		         	name=varname(dsid,i);
		         	fmt=varfmt(dsid,i);
		         	if (vartype(dsid,i)='C') then do;
		            	content=getvarc(dsid,i);
		            	if (fmt ne '') then content=left(putc(content,fmt));
		            	output;
		            end;
		      	end;
		   	end;
		   rc=close(dsid);		
		run;
	*/

	%local __count 
		__nobs 
		__nmiss; 

	PROC SQL noprint;
		select count(*) into :__nobs
		from &lib..&dsn;
		select count(&var) into :__count
		from &lib..&dsn;
	quit;
	%let __nmiss=%eval(&__nobs - &__count);

	data _null_;
 		%if not %macro_isblank(_count_) %then %do;
			call symput("&_count_",%eval(&__count));
		%end;
 		%if not %macro_isblank(_nmiss_)  %then %do;	
			call symput("&_nmiss_",%eval(&__nmiss));
		%end;
	run;

	%exit:
%mend var_count;

%macro _example_var_count;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local count nmiss;

	%_dstest28;
	%*ds_print(_dstest28);

	%put;
	%put (i) Dummy example with missing parameters;
	%var_count(_dstest28, geo);
	%if &count= and &nmiss= %then 		%put OK: TEST PASSED - Dummy test: nothing returned;
	%else 								%put ERROR: TEST FAILED - Dummy test: output returned;

	%put;
	%put (ii) Dummy example with a non existing DUMMY variable;
	%var_count(_dstest28, dummy, _count_=count, _nmiss_=nmiss, lib=WORK);
	%if &count= and &nmiss= %then 		%put OK: TEST PASSED - DUMMY variable returns: error;
	%else 								%put ERROR: TEST FAILED - DUMMY variable returns: no error;

	%put;
	%put (iii) We then use it over a non-empty dataset with missing observation: _dstest1;
	%_dstest1;
	%var_count(_dstest1, a, _count_=count, lib=WORK);
	%if &count=0 %then 		%put OK: TEST PASSED - Test on A variable returns: &count;
	%else 					%put ERROR: TEST FAILED - Test on A variable returns: &count;

	%put;
	%put (iv) We count the number of non-missing values for a character variable GEO in a simple table;
	%var_count(_dstest28, geo, _count_=count, _nmiss_=nmiss, lib=WORK);
	%if &count=4 and &nmiss=2 %then 	%put OK: TEST PASSED - Test on GEO variable returns: count=4 and nmiss=2;
	%else 								%put ERROR: TEST FAILED - Test on GEO variable returns: count=&count and nmiss=&nmiss;

	%put;
	%put (v) We count the number of non-missing values for a character variable VALUE in a simple table;
	%var_count(_dstest28, value, _count_=count, _nmiss_=nmiss, lib=WORK);
	%if &count=4 and &nmiss=2 %then 		%put OK: TEST PASSED - Test on VALUE variable returns: count=4 and nmiss=2;
	%else 								%put ERROR: TEST FAILED - Test on VALUE variable returns: count=&count and nmiss=&nmiss;

	%work_clean(_dstest1);
	%work_clean(_dstest28);
%mend _example_var_count;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_count; 
*/

/** \endcond */

