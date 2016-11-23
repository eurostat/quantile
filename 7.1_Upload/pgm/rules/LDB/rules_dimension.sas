
%macro rule_dimcol(tab, dimcol);

	%let Utab=%upcase(&tab);

	/* dimensions adjusted for Longitudinal indicators */
	%if &Utab=LI23 or &Utab=LI24 or &Utab=LI51 or 
		&Utab=DI30A or &Utab=DI30B or &Utab=DI30C %then %do;
		%let dimcol=&dimcol unit;
	%end;

	/* instead of setting the variable:
	data _null_;
		call symput("&dimcol","&&&dim");
	run;
	* we return it  */
	%quote(&dimcol)

%mend rule_dimcol;

%macro rule_dimcolC(tab, dimcolC);

	%quote(&dimcolC)

%mend rule_dimcolC;


%macro _test_rule_dimensions;
	%if &_SASSERVERNAME='SASMain' %then %do;
		%let eusilc=/ec/prod/server/sas/0eusilc;
	%end;
	%else %do;
		%let eusilc=Z:;
	%end;

	options MAUTOSOURCE SASAUTOS=(SASAUTOS "&eusilc/library/autocall");  
	%set_dspath(&eusilc, legacy=1);
	libname lrdb "&l_rdb";

	%let dimcol=;
	%let dimcolC=;

	%let tab=DI30b;
	%define_dimensions(&tab, lib=lrdb, _dimcol_=dimcol);
	%put (i) for Longitudinal indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dimcol(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=LVHL33;
	%define_dimensions(&tab, lib=lrdb, _dimcol_=dimcol);
	%put (ii) for Longitudinal indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dimcol(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

%mend _test_rule_dimensions;
/* %_test_rule_dimensions; */ 
