%macro data_check(tab, geo, years, _yyyy_=, lib=' ');
	%if "&lib"="' '" %then %do;
		%let lib=WORK;
	%end;

	/* test if the datasets is empty and change the years variables */
	%local nobs;

	PROC SQL noprint;
	SELECT DISTINCT count(geo) as N 
		into :nobs
		from &lib..&tab (where=(time in (&years) and rule_fmt_geo2cc(geo) in (&geo)));
	quit;

	%if &nobs=0 %then %do;
		%put No observation found in &tab for geo and years considered;
		%goto exit;
	%end;

	PROC SQL noprint;
	SELECT DISTINCT time as Ny 
		into :nobs separated by ',' 
		from  &lib..&tab (where=(time in (&years) and rule_fmt_geo2cc(geo) in (&geo)));
	quit;

	data _null_;
		call symput("&_yyyy_","&nobs");
	run;

	%exit:
%mend data_check;


%macro _test_data_check;
;
%mend _test_data_check;

