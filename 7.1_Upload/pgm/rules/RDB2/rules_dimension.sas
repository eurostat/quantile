
%macro rule_dim_col(ind, dimcol);
	;	/* do nothing */
	%quote(&dimcol)

%mend rule_dim_col;

%macro rule_dim_colC(ind, dimcolC);
	;	/* do nothing */
	%quote(&dimcolC)

%mend rule_dim_colC;


%macro _test_rules_dimension;
	%if &_SASSERVERNAME='SASMain' %then %do;
		%let eusilc=/ec/prod/server/sas/0eusilc;
	%end;
	%else %do;
		%let eusilc=Z:;
	%end;

	options MAUTOSOURCE SASAUTOS=(SASAUTOS "&eusilc/library/autocall");  
	%set_dspath(&eusilc, legacy=1);
	libname rdb2 "&c_rdb2";

	%let dimcol=;
	%let dimcolC=;

	%let tab=PW01;
	%define_dimensions(&tab, lib=rdb2, _dimcol_=dimcol);
	%put for RDB2 indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dim_col(&tab, %quote(&dimcol));
	%put res:  updated dimensions are "&dimcol" (no change);
%mend _test_rules_dimension;
/* %_test_rules_dimension; */ 
