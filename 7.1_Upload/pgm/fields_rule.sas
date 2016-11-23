
%macro fields_rule(tab, grpdim);

	%let Utab=%upcase(&tab);

	/* fields adjusted for RDB indicators */
	%if &Utab=DI23 or    &Utab=DI27 or 
		&Utab=LI09B or   &Utab=LI10B or   &Utab=LI22B or   &Utab=LI60 or    &Utab=LI41 or 
		&Utab=IW15 or    &Utab=IW16 or 
		&Utab=OV9B2 or 
		&Utab=PEPS07 or  &Utab=PEPS11 or  &Utab=PEPS60 or 
		&Utab=MDDD17 or  &Utab=MDDD21 or  &Utab=MDDD60 or 
		&Utab=LVHL17 or  &Utab=LVHL21 or  &Utab=LVHL60 or 
		&Utab=PEES08 or 
		&Utab=MDHO05 or  &Utab=MDHO06A or &Utab=MDHO06B or &Utab=MDHO06C or &Utab=MDHO06D or &Utab=MDHO06Q or 
		&Utab=LVHO08A or &Utab=LVHO08B or &Utab=LVHO07A or &Utab=LVHO07B or &Utab=LVHO07C or &Utab=LVHO07D or 
		&Utab=LVHO07E or &Utab=LVHO05A or &Utab=LVHO06 or  &Utab=LVHO06Q or &Utab=LVHO05B or &Utab=LVHO05C or 
		&Utab=LVHO05D or &Utab=LVHO05Q or &Utab=LVHO15 or  &Utab=LVHO16 or  &Utab=LVHO25 or  &Utab=LVHO26 or 
		&Utab=LVHO27 or  &Utab=LVHO28 or  &Utab=LVHO29 or  &Utab=LVHO30 or  &Utab=LVHO50A or &Utab=LVHO50B or 
		&Utab=LVHO50C or &Utab=LVHO50D
		/* %if &Utab in "DI23", "DI27", "LI09B", "LI10b", "LI22B", "LI60", "LI41", "IW15", "IW16", "OV9B2", 
		"PEPS07", "PEPS11", "PEPS60", "MDDD17", "MDDD21", "MDDD60", "LVHL17", "LVHL21", "LVHL60", 
		"PEES08", "MDHO05", "MDHO06A", "MDHO06B", "MDHO06C", "MDHO06D", "MDHO06Q", 
		"LVHO08A", "LVHO08B", "LVHO07A", "LVHO07B", "LVHO07C", "LVHO07D", "LVHO07E", 
		"LVHO05A", "LVHO06", "LVHO06Q", "LVHO05B", "LVHO05C", "LVHO05D", "LVHO05Q", 
		"LVHO15", "LVHO16", "LVHO25", "LVHO26", "LVHO27", "LVHO28", "LVHO29", "LVHO30", 
		"LVHO50A", "LVHO50B", "LVHO50C", "LVHO50D"                                 */
			%then %do; /* UNIT is added on EUROBASE */
		%let dimcol=&dimcol unit;
	%end;
	%else %if &Utab=PNP9 %then %do;
		/* INDIC_IL (with static value LI_R_MD60) is added on EUROBASE */
		%let dimcol=&dimcol "LI_R_MD60 ";
	%end;

	/* fields adjusted for Early indicators */
	%else %if &Utab=E_MDES01 or &Utab=E_MDES02 or 
		&Utab=E_MDES03 or &Utab=E_MDES04 or &Utab=E_MDES05 or &Utab=E_MDES09 or &Utab=E_MDDU01 or 
		&Utab=E_MDDU02 or &Utab=E_MDDU03 or 
		&Utab=E_MDDU04 or &Utab=E_MDDU05 %then %do;
		%let grpdim=&grpdim unit;
	%end;

	/* dimensions adjusted for Longitudinal indicators */
	%else %if &Utab=LI23 or &Utab=LI24 or &Utab=LI51 or 
		&Utab=DI30A or &Utab=DI30B or &Utab=DI30C %then %do;
		%let dimcol=&dimcol unit;
	%end;

	/* instead of setting the variable:
	data _null_;
		call symput("&grpdim","&&&dim");
	run;
	* we return it  */
	%quote(&grpdim)

%mend fields_rule;


%macro _example_fields_rule;
	%if %symexist(EUSILC) %then 	%let SETUP_PATH=&EUSILC;
	%else 		%let SETUP_PATH=/ec/prod/server/sas/0eusilc; 
	%include "&SETUP_PATH/library/autocall/_setup_.sas";
	%include "&SETUP_PATH/library/pgm/fields_to_list.sas";

	%_setup_env_(legacy=yes, test=yes);
	libname rdb "&G_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 
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
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%let dimcolC=%fields_rule(&tab, %quote(&dimcolC));
	%put res:  updated fields are &dimcol and &dimcolC;

    %let tab=PNP9;
    %fields_to_list(&tab, lib=rdb, _list_=dimcol);
    %put (ii) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
    %put res:  updated dimensions are &dimcol;

	%let tab=LVHO05a;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (iii) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=LI22;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (iv) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	%let tab=LI45;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (v) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	/* test RDB2 indicators */
	%let tab=PW01;
	%fields_to_list(&tab, lib=rdb2, _list_=dimcol);
	%put (vi) for RDB2 indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are "&dimcol" (no change);

	/* test Early indicators */
	%let tab=E_MDES04;
	%fields_to_list(&tab, lib=e_rdb, _list_=dimcol);
	%put (vii) for Early indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=E_MDDD11;
	%fields_to_list(&tab, lib=e_rdb, _list_=dimcol);
	%put (viii) for Early indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	/* test Longitudinal indicators */
	%let tab=DI30b;
	%fields_to_list(&tab, lib=l_rdb, _list_=dimcol);
	%put (ix) for Longitudinal indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=LVHL33;
	%fields_to_list(&tab, lib=l_rdb, _list_=dimcol);
	%put (x) for Longitudinal indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%fields_rule(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

%mend _example_fields_rule;
%_example_fields_rule; 