
%macro fields_upload_rule(ind, grpdim);

	%let Uind=%upcase(&ind);

	/* fields adjusted for RDB indicators */
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
		%let grpdim=&grpdim unit;
	%end;
	%else %if &Uind=PNP9 %then %do;
		/* INDIC_IL (with static value LI_R_MD60) is added on EUROBASE */
		%let grpdim=&grpdim "LI_R_MD60 ";
	%end;

	/* fields adjusted for Early indicators */
	%else %if &Uind=E_MDES01 or &Uind=E_MDES02 or 
		&Uind=E_MDES03 or &Uind=E_MDES04 or &Uind=E_MDES05 or &Uind=E_MDES09 or &Uind=E_MDDU01 or 
		&Uind=E_MDDU02 or &Uind=E_MDDU03 or 
		&Uind=E_MDDU04 or &Uind=E_MDDU05 %then %do;
		%let grpdim=&grpdim unit;
	%end;

	/* dimensions adjusted for Longitudinal indicators */
	%else %if &Uind=LI23 or &Uind=LI24 or &Uind=LI51 or 
		&Uind=DI30A or &Uind=DI30B or &Uind=DI30C %then %do;
		%let grpdim=&grpdim unit;
	%end;

	/* instead of setting the variable:
	data _null_;
		call symput("&grpdim","&&&dim");
	run;
	* we return it  */
	%quote(&grpdim)

%mend fields_upload_rule;


%macro _example_fields_upload_rule;
	%if %symexist(EUSILC) %then 	%let SETUP_PATH=&EUSILC;
	%else 		%let SETUP_PATH=/ec/prod/server/sas/0eusilc; 
	%include "&SETUP_PATH/library/autocall/_setup_.sas";
	%include "&SETUP_PATH/library/autocall/_setup_env_.sas";
  	%_setup_default_;
	%include "&SETUP_PATH/library/autocall/_setup_default_.sas";
	%_setup_env_(legacy=&G_IS_LEGACY, test=&G_IS_IN_TEST);

	%include "&SETUP_PATH/library/pgm/fields_to_list.sas";

	/* libname ex_data "&library/data"; /* ex_data is SILCFMT! */
	libname rdb "&G_C_RDB"; /* "&eusilc/IDB_RDB/C_RDB"; */ 
	libname rdb2 "&G_C_RDB2"; 
	libname e_rdb "&G_E_RDB"; 
	libname l_rdb "&G_L_RDB"; 

	%local dimcol;
	%local dimcolC;

	/* test RDB indicators */

	%let tab=DI10;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol, _clist_=dimcolC);
	%put (i) for RDB indicator &tab; 
	%put res:  output by fields_to_list are dimcol=&dimcol and dimcolC=&dimcolC;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%let dimcolC=%fields_upload_rule(&tab, %quote(&dimcolC));
	%put res:  updated fields are &dimcol and &dimcolC;

    %let tab=PNP9;
    %fields_to_list(&tab, lib=rdb, _list_=dimcol);
    %put (ii) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
    %put res:  updated dimensions are &dimcol;

	%let tab=LVHO05a;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (iii) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=LI22;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (iv) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	%let tab=LI45;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (v) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	/* test RDB2 indicators */
	%let tab=PW01;
	%fields_to_list(&tab, lib=rdb2, _list_=dimcol);
	%put (vi) for RDB2 indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are "&dimcol" (no change);

	/* test Early indicators */
	%let tab=E_MDES04;
	%fields_to_list(&tab, lib=e_rdb, _list_=dimcol);
	%put (vii) for Early indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=E_MDDD11;
	%fields_to_list(&tab, lib=e_rdb, _list_=dimcol);
	%put (viii) for Early indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	/* test Longitudinal indicators */
	%let tab=DI30b;
	%fields_to_list(&tab, lib=l_rdb, _list_=dimcol);
	%put (ix) for Longitudinal indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=LVHL33;
	%fields_to_list(&tab, lib=l_rdb, _list_=dimcol);
	%put (x) for Longitudinal indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_upload_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

%mend _example_fields_upload_rule;
/* %_example_fields_upload_rule; */