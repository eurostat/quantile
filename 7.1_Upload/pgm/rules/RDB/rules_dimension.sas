/* Adjustment of dimensions/fields names for RDB indicators 
 */

%macro rule_dim_col(ind, dimcol);

	%let Uind=%upcase(&ind);

	%if &Uind=DI23 or    &Uind=DI27 or 
		&Uind=LI09B or   &Uind=LI10B or   &Uind=LI22B or   &Uind=LI60 or    &Uind=LI41 or 
		&Uind=IW15 or    &Uind=IW16 or 
		&Uind=OV9B2 or 
		&Uind=PEPS07 or  &Uind=PEPS11 or  &Uind=PEPS60 or 
		&Uind=MDDD17 or  &Uind=MDDD21 or  &Uind=MDDD60 or 
		&Uind=LVHL17 or  &Uind=LVHL21 or  &Uind=LVHL60 or 
		&Uind=PEES08 or 
		&Uind=MDHO05 or  &Uind=MDHO06A or &Uind=MDHO06B or &Uind=MDHO06C or &Uind=MDHO06D or &Uind=MDHO06Q or 
		&Uind=LVHO08A or &Uind=LVHO08B or &Uind=LVHO07A or &Uind=LVHO07B or &Uind=LVHO07C or &Uind=LVHO07D or 
		&Uind=LVHO07E or &Uind=LVHO05A or &Uind=LVHO06 or  &Uind=LVHO06Q or &Uind=LVHO05B or &Uind=LVHO05C or 
		&Uind=LVHO05D or &Uind=LVHO05Q or &Uind=LVHO15 or  &Uind=LVHO16 or  &Uind=LVHO25 or  &Uind=LVHO26 or 
		&Uind=LVHO27 or  &Uind=LVHO28 or  &Uind=LVHO29 or  &Uind=LVHO30 or  &Uind=LVHO50A or &Uind=LVHO50B or 
		&Uind=LVHO50C or &Uind=LVHO50D
		/* %if &Uind in "DI23", "DI27", "LI09B", "LI10b", "LI22B", "LI60", "LI41", "IW15", "IW16", "OV9B2", 
		"PEPS07", "PEPS11", "PEPS60", "MDDD17", "MDDD21", "MDDD60", "LVHL17", "LVHL21", "LVHL60", 
		"PEES08", "MDHO05", "MDHO06A", "MDHO06B", "MDHO06C", "MDHO06D", "MDHO06Q", 
		"LVHO08A", "LVHO08B", "LVHO07A", "LVHO07B", "LVHO07C", "LVHO07D", "LVHO07E", 
		"LVHO05A", "LVHO06", "LVHO06Q", "LVHO05B", "LVHO05C", "LVHO05D", "LVHO05Q", 
		"LVHO15", "LVHO16", "LVHO25", "LVHO26", "LVHO27", "LVHO28", "LVHO29", "LVHO30", 
		"LVHO50A", "LVHO50B", "LVHO50C", "LVHO50D"                                 */
			%then %do; /* UNIT is added on EUROBASE */
		%let dimcol=&dimcol unit;
	%end;
	%else %if &Uind=PNP9 %then %do;
		/* INDIC_IL (with static value LI_R_MD60) is added on EUROBASE */
		%let dimcol=&dimcol "LI_R_MD60 ";
	%end;

	/* instead of setting the variable:
	data _null_;
		call symput("&dimcol","&&&dim");
	run;
	* we return it  */
	%quote(&dimcol)

%mend rule_dim_col;

%macro rule_dim_colC(ind, dimcolC);

	%let Uind=%upcase(&ind);

	%if &Uind=DI10 %then %do; /* the field CURRENCY is replaced by UNIT on EUROBASE */
		%let dimcolC=%sysfunc(tranwrd(&dimcolC,CURRENCY,UNIT));
	%end;
	%else %if &Uind=PNP9 %then %do; /* INDIC_IL (with static value LI_R_MD60) is added on EUROBASE */
		%let dimcolC=&dimcolC,INDIC_IL;
	%end;

	%quote(&dimcolC)

%mend rule_dim_colC;


%macro _test_rules_dimension;
	%if &_SASSERVERNAME='SASMain' %then %do;
		%let eusilc=/ec/prod/server/sas/0eusilc;
	%end;
	%else %do;
		%let eusilc=Z:;
	%end;
	/* note: we should use %local_or_server here... 
		 %let eusilc=local_or_server; 
	 */

	options MAUTOSOURCE SASAUTOS=(SASAUTOS "&eusilc/library/autocall");  
	%set_dspath(&eusilc, legacy=1);
	libname rdb "&c_rdb";

	%let dimcol=;
	%let dimcolC=;

	%let tab=DI10;
	%define_dimensions(&tab, lib=rdb, _dimcol_=dimcol, _dimcolC_=dimcolC);
	%put (i) for RDB indicator &tab; 
	%put res:  output by define_dimensions are dimcol=&dimcol and dimcolC=&dimcolC;
	%let dimcol=%rule_dim_col(&tab, %quote(&dimcol));
	%let dimcolC=%rule_dim_colC(&tab, %quote(&dimcolC));
	%put res:  updated fields are &dimcol and &dimcolC;

    %let tab=PNP9;
    %define_dimensions(&tab, lib=rdb, _dimcol_=dimcol);
    %put (ii) for RDB indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dim_col(&tab, %quote(&dimcol));
    %put res:  updated dimensions are &dimcol;

	%let tab=LVHO05a;
	%define_dimensions(&tab, lib=rdb, _dimcol_=dimcol);
	%put (iii) for RDB indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dim_col(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=LI22;
	%define_dimensions(&tab, lib=rdb, _dimcol_=dimcol);
	%put (iv) for RDB indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dim_col(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	%let tab=LI45;
	%define_dimensions(&tab, lib=rdb, _dimcol_=dimcol);
	%put (v) for RDB indicator=&tab and dimcol="&dimcol" output by define_dimensions;
	%let dimcol=%rule_dim_col(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

%mend _test_rules_dimension;
/* %_test_rules_dimension; */ 
