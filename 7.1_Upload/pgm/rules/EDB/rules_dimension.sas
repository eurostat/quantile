
%macro rule_dimcol(tab, dimcol);

	%let Utab=%upcase(&tab);

	/* dimensions adjusted for Early indicators */
	%if &Utab=E_MDES01 or &Utab=E_MDES02 or 
		&Utab=E_MDES03 or &Utab=E_MDES04 or &Utab=E_MDES05 or &Utab=E_MDES09 or &Utab=E_MDDU01 or 
		&Utab=E_MDDU02 or &Utab=E_MDDU03 or 
		&Utab=E_MDDU04 or &Utab=E_MDDU05 %then %do;
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
	libname erdb "&e_rdb";

	%let dimcol=;
	%let dimcolC=;

	%let tab=E_MDES04;
	%define_dimensions(&tab, lib=erdb, _dimcol_=dimcol);
	%put (i) for Early indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dimcol(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=E_MDDD11;
	%define_dimensions(&tab, lib=erdb, _dimcol_=dimcol);
	%put (ii) for Early indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dimcol(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

%mend _test_rule_dimensions;
/* %_test_rule_dimensions; */ 
