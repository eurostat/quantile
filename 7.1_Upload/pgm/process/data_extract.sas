/*
*/

%macro data_extract(dsn, tab, geo, yyyy, lib=' ');
	%if "&lib"="' '" %then %do;
		%let lib=WORK;
	%end;

	/* DATA _null_;
		set &lib..&tab(where=(time in (&yyyy) and rule_fmt_geo2cc(geo) in (&geo))) end=last;
	run; */

	PROC SQL noprint;
		create table WORK.&dsn as 
			select * from &lib..&tab 
			where time in &yyyy and rule_fmt_geo2cc(geo) in &geo;
		quit;

	%rule_ind_filter(&dsn, &tab);

%mend data_extract;


%macro _test_data_extract;
;
%mend _test_data_extract;
