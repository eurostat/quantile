
%macro ncfile_define(tab, yyyy, odb=' ', _ncfile_=' ');
	%if %symexist(CURDIR)=0 %then %do;
		%let CURDIR=&EUSILC/%path_egp(path=pathdrive);
	%end; /* note that CURDIR should be defined as a global variable */
	%if "&odb"="' '" %then %do;
		%let odb=&CURDIR; 
	%end;		

	%local ncfile;
	/* Define the output filename:
	* method #1:
	%let Utab=%sysfunc(compress(%upcase(&tab)));
	%let sdat = %sysfunc(putn("&sysdate"d,yymmdd6.));
	* or: %let sdat=%sysfunc(putn(%eval(%sysfunc(today())),yymmdd6.)); 
	%let Cyyy=%sysfunc(compress(&yyyy));
	%let nc = &sdat._&Cyyy._&Utab;
	* method #2:                                                        */
	%let Utab=%upcase(&tab);
	%let nc = %sysfunc(putn("&sysdate"d,yymmdd6.))_%sysfunc(compress(%quote(&yyyy)))_%sysfunc(compress(%quote(&Utab)));
	/* method #3: 
  	DATA _null_;
		sdat = put("&sysdate"d,yymmdd6.);
		nc = sdat||"_"||compress("&yyyy")||"_"||compress("&Utab");
		call symput("nc",nc);
	run;                      */
	%let ncfile=&odb/&nc..txt;

	data _null_;
		call symput("&_ncfile_","&ncfile");
	run;

	/* %quote(&ncfile) */
%mend ncfile_define;


%macro _test_ncfile_define;
;
%mend _test_ncfile_define;