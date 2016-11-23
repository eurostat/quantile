/** \cond */
/** 
## fields_to_list {#sas_fields_to_list}
Return the list of main dimensions/fields of a given dataset to be used for upload 
into Eurobase. 
Usually used for automatic formatting of the upload files.

	%fields_to_list(dsn, _list_=, _clist_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `_list_` : name (string) of the macro variable storing the dimensions/fields;
* `_clist_` : name (string) of the macro variable storing the (comma separated) uppercase fields;
* `lib` : (_option_) name of the input library; by default: `WORK`.
 
### Returns
* `_list_` : name (string) of the macro variable storing the list of (blank separated) main 
	dimensions/fields of the input table are set;
* `_clist_` : name (string) of the macro variable storing the corresponding list of (comma 
	separated) uppercase dimensions.

### Examples

	%let dimcol=;
	%fields_to_list(LI01, lib=rdb, _list_=dimcol) 
	
returns: `dimcol=geo time indic_il hhtyp currency`.

	%let dimcol=;
	%fields_to_list(LI02, lib=rdb, _list_=dimcol) 

returns: `dimcol=geo time age sex indic_il unit`.

Run macro `%%_example_fields_to_list` for more examples.

### Note
Note the special treatment of the `unit` field: in the case this field is reduced to 
one instance only (_i.e._ `SELECT count(DISTINCT unit) into :N returns N=1`), it is not sent 
to Eurobase (_i.e._, not used as a dimension). For instance, opposite to `LI02` above:

	%let dimcol=;
	%let `%fields_to_list(LI03, lib=rdb, _list_=dimcol)` 
	
will return: `dimcol=geo time age sex indic_il` ignoring the `unit` field. 

From `dimcol`, it is very easy to retrieve the list of (comma separated) dimensions:

	%let dimcolcomma=%sysfunc(upcase(%sysfunc(translate(&dimcol,","," "))));

that is otherwise returned through `_clist_`.

Do not pass a macro variable named `_list_` (or `_clist_`) to the positional parameter 
`_list_` (or `_clist_`) used in fields_to_list as SAS is not able to handle it (where is the 
notion of 'local' variable gone?!!!). Instead, always remember: SAS is not a programming language, 
it is a stupid language!	
*/ /** \cond */
 
%macro fields_to_list(/*input*/	 dsn, 
					  /*output*/ _list_=, _clist_=,
					  /*option*/ lib=);

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_list_) EQ 1 and %macro_isblank(_clist_) EQ 1,		
			txt=!!! output macro variables _list_ or _clist_ need to be set !!!) %then
		%goto exit;

	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/* prepare the dataset; extract the list of variables */
	%let TMP=_tmp_fields_to_list;
	PROC DATASETS nolist;
		CONTENTS data=&lib..&dsn out=WORK.&TMP noprint;
	quit;

	/* sort */	
	PROC SORT
		DATA=&TMP(keep=name varnum) OVERWRITE;
		BY varnum name;
	quit;

	/* determine if "unit" is one field of the given database */
	%let find_unit=0;
	DATA _NULL_;
		SET &TMP;
		if upcase(name) = "UNIT" then do;
			call symput('find_unit',1);
			stop;
		end;
	run;

	%if &find_unit=1 %then %do;
		/* define how many distinct values for UNIT when it exists */
		PROC SQL noprint; 
			SELECT count(DISTINCT unit) as count 
			into :count
			from &lib..&dsn;
		quit;
	%end;
	%else %do;
		%let count=0;
	%end;

	%let LENGTH_FIELD_STRING=50;
	%let MAX_NUMBER_FIELDS=10;

	/* extract the list of dimensions, excluding UNIT when necessary, i.e. when only one instance
	 * of unit exists. 
	 * This rule is in fact not valid for all variables: see the outcomes of the test macro below;
	 * some further formatting will be needed (e.g., through the application of another filter) 
	 */
	DATA _NULL_;
		SET &TMP;
		array v(&MAX_NUMBER_FIELDS) $&LENGTH_FIELD_STRING;
		retain i (1);
		retain v;
		length dimcol $&LENGTH_FIELD_STRING;
		length dimcolC $&LENGTH_FIELD_STRING; 

		if name ne "ivalue" then do;
			if upcase(name) ^= "UNIT" or &count ne 1 then do;
				v(i) = name;
				i = i + 1;
			end; /* else if upcase(name) = "UNIT" and count=1: do nothing, go to next field */
		end;
		else do;
			dimcol = lowcase(v(1)); /* !!! note here the use of lowcase !!! */
			dimcolC = v(1);

			do j = 2 to i-1;
				dimcol = trim(dimcol)||" "||trim(lowcase(v(j)));
				dimcolC = trim(dimcolC)||","||trim(v(j));
			end;

			if "&_list_"^="' '"  then do;
				call symput("&_list_",trim(dimcol));
			end;
			if "&_clist_"^="' '"  then do;
				call symput("&_clist_",trim(upcase(dimcolC)));
			end;
			stop; /* leave */
		end;
	run;
 
	/* do some cleaning */
	%work_clean(&TMP)

	%exit:
%mend fields_to_list;


%macro _example_fields_to_list;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	libname rdb "&G_PING_C_RDB";
	libname erdb "&G_PING_E_RDB";
	libname rdb2 "&G_PING_C_RDB2";
	libname lrdb "&G_PING_L_RDB";

	%put We test fields_to_list over all RDB datasets;
	%let unmatchedField=none;

	%let dimcol=;
	%let dimcolC=;
	%macro _example_indic_fields(tab, rdb, FIELDS);
		/* return the list dimcol of identified dimensions */
		%fields_to_list(&tab, lib=&rdb, _list_=dimcol, _clist_=dimcolC);
		/* check  with what was expected */
		%if "&dimcolC"^=&FIELDS %then %do;
			%let nw_dim=%sysfunc(countw(&dimcol),%str( ));
			%let nw_fields=%sysfunc(countw(&FIELDS));
			%do i=1 %to &nw_fields;
				%let field=%sysfunc(lowcase(%scan(&FIELDS, &i, ",")));
				%let pos=%sysfunc(find(&dimcol, &field));
				%if &pos<=0 %then %do;
					%if "&unmatchedField"="none" %then %do;
						%let unmatchedField=%str((&tab,&field));
					%end;
					%else %do;
						%let unmatchedField=%str(&unmatchedField,%str((&tab,&field)));
					%end;
				%end;
			%end;
		%end;

	%mend;

	/* Among the list of indicators that return different dimensions, most are 
	* owing to the fact that some variable (UNIT) is missing:
	%_example_indic_fields(LI09b, FIELDS="GEO,TIME,HHTYP,UNIT");
	%_example_indic_fields(LI10b, FIELDS="GEO,TIME,HHTYP,UNIT");
	%_example_indic_fields(DI23, FIELDS="GEO,TIME,DEG_URB,INDIC_IL,UNIT");
	%_example_indic_fields(DI27, FIELDS="GEO,TIME,ISCED97,INDIC_IL,UNIT");
	...

	* Only one indicator differs because a variable (namely CURRENCY) has been
	* renamed (into UNIT):
	%_example_indic_fields(DI10, FIELDS="GEO,TIME,INDIC_IL,SUBJNMON,UNIT");

	* Another indicator because a field (namely INDIC_IL with unique value "LI_R_MD60") 
	* is manually added:	
	%_example_indic_fields(PNP9, FIELDS="GEO,TIME,AGE,SEX,HHTYP,INDIC_IL");
	*/  

	/* Test of dimensions for RDB indicators */

    %_example_indic_fields(LI01, rdb, FIELDS="GEO,TIME,INDIC_IL,HHTYP,CURRENCY");
	%_example_indic_fields(LI02, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT");
	* %_example_indic_fields(OT01, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT");
	%_example_indic_fields(LI03, rdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL");
	* %_example_indic_fields(OT03, rdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL");
	%_example_indic_fields(LI04, rdb, FIELDS="GEO,TIME,AGE,SEX,WSTATUS,INDIC_IL");
	* %_example_indic_fields(OT02, rdb, FIELDS="GEO,TIME,AGE,SEX,WSTATUS,INDIC_IL");
	%_example_indic_fields(LI06, rdb, FIELDS="GEO,TIME,AGE,SEX,HHTYP,WORKINT,INDIC_IL");
	* %_example_indic_fields(OT05, rdb, FIELDS="FIELDS=GEO,TIME,AGE,SEX,HHTYP,WORKINT,INDIC_IL");
	%_example_indic_fields(LI07, rdb, FIELDS="GEO,TIME,AGE,SEX,ISCED97,INDIC_IL");
	* %_example_indic_fields(OT06, rdb, FIELDS="GEO,TIME,AGE,SEX,ISCED97,INDIC_IL");
	%_example_indic_fields(LI08, rdb, FIELDS="GEO,TIME,AGE,SEX,TENURE,INDIC_IL");
	* %_example_indic_fields(OT04, rdb, FIELDS="GEO,TIME,AGE,SEX,TENURE,INDIC_IL");
	%_example_indic_fields(LI09, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL");
	%_example_indic_fields(LI09b, rdb, FIELDS="GEO,TIME,HHTYP,UNIT");
	%_example_indic_fields(LI10, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL");
	%_example_indic_fields(LI10b, rdb, FIELDS="GEO,TIME,HHTYP,UNIT");
	%_example_indic_fields(LI11, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL");
	%_example_indic_fields(LI22, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL");
	%_example_indic_fields(LI22b, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT");
	%_example_indic_fields(LI31, rdb, FIELDS="GEO,TIME,AGE,SEX,CITIZEN");
	%_example_indic_fields(LI32, rdb, FIELDS="GEO,TIME,AGE,SEX,C_BIRTH");
	%_example_indic_fields(LI41, rdb, FIELDS="GEO,TIME,UNIT");
	%_example_indic_fields(LI45, rdb, FIELDS="GEO,TIME,AGE,SEX");
	%_example_indic_fields(LI48, rdb, FIELDS="GEO,TIME,DEG_URB");
	%_example_indic_fields(LI60, rdb, FIELDS="GEO,TIME,AGE,ISCED97,UNIT");

	%_example_indic_fields(DI01, rdb, FIELDS="GEO,TIME,INDIC_IL,CURRENCY,QUANTILE");
	%_example_indic_fields(DI02, rdb, FIELDS="GEO,TIME,INCGRP,INDIC_IL,CURRENCY");
	%_example_indic_fields(DI03, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT"); 
	%_example_indic_fields(DI04, rdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL,UNIT");
	%_example_indic_fields(DI05, rdb, FIELDS="GEO,TIME,AGE,SEX,WSTATUS,INDIC_IL,UNIT");
	%_example_indic_fields(DI07, rdb, FIELDS="GEO,TIME,AGE,SEX,HHTYP,WORKINT,INDIC_IL,UNIT");
	%_example_indic_fields(DI08, rdb, FIELDS="GEO,TIME,AGE,SEX,ISCED97,INDIC_IL,UNIT");
	%_example_indic_fields(DI09, rdb, FIELDS="GEO,TIME,AGE,SEX,TENURE,INDIC_IL,UNIT");
	%_example_indic_fields(DI10, rdb, FIELDS="GEO,TIME,INDIC_IL,SUBJNMON,UNIT");
	%_example_indic_fields(DI11, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL");
	%_example_indic_fields(DI12, rdb, FIELDS="GEO,TIME,INDIC_IL");
	%_example_indic_fields(DI12b, rdb, FIELDS="GEO,TIME,INDIC_IL");
	%_example_indic_fields(DI12c, rdb, FIELDS="GEO,TIME,INDIC_IL");
	%_example_indic_fields(DI13, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT");
	%_example_indic_fields(DI13b, rdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL,UNIT");
	%_example_indic_fields(DI14, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT");
	%_example_indic_fields(DI14b, rdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL,UNIT");
	%_example_indic_fields(DI15, rdb, FIELDS="GEO,TIME,AGE,SEX,CITIZEN,INDIC_IL,UNIT");
	%_example_indic_fields(DI16, rdb, FIELDS="GEO,TIME,AGE,SEX,C_BIRTH,INDIC_IL,UNIT");
	%_example_indic_fields(DI17, rdb, FIELDS="GEO,TIME,AGE,SEX,DEG_URB,INDIC_IL,UNIT");
	%_example_indic_fields(DI20, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT");
	%_example_indic_fields(DI23, rdb, FIELDS="GEO,TIME,DEG_URB,INDIC_IL,UNIT");
	%_example_indic_fields(DI27, rdb, FIELDS="GEO,TIME,ISCED97,INDIC_IL,UNIT");

	%_example_indic_fields(IW01, rdb, FIELDS="GEO,TIME,AGE,SEX,WSTATUS");
	%_example_indic_fields(IW02, rdb, FIELDS="GEO,TIME,HHTYP");
	%_example_indic_fields(IW03, rdb, FIELDS="GEO,TIME,HHTYP,WORKINT");
	%_example_indic_fields(IW04, rdb, FIELDS="GEO,TIME,ISCED97");
	%_example_indic_fields(IW05, rdb, FIELDS="GEO,TIME,WSTATUS,SEX");
	%_example_indic_fields(IW06, rdb, FIELDS="GEO,TIME,DURATION");
	%_example_indic_fields(IW07, rdb, FIELDS="GEO,TIME,WORKTIME");
	%_example_indic_fields(IW15, rdb, FIELDS="GEO,TIME,AGE,SEX,CITIZEN,UNIT");
	%_example_indic_fields(IW16, rdb, FIELDS="GEO,TIME,AGE,SEX,C_BIRTH,UNIT");

	%_example_indic_fields(PNP2, rdb, FIELDS="GEO,TIME,SEX,INDIC_IL");
	%_example_indic_fields(PNP3, rdb, FIELDS="GEO,TIME,SEX,INDIC_IL");
	* %_example_indic_fields(PNS2, rdb, FIELDS="GEO,TIME,SEX,INDIC_IL");
	%_example_indic_fields(PNP9, rdb, FIELDS="GEO,TIME,AGE,SEX,HHTYP,INDIC_IL");
	%_example_indic_fields(PNP10, rdb, FIELDS="GEO,TIME,INDIC_IL,SEX,HHTYP");
	* %_example_indic_fields(PNP11, rdb, FIELDS="GEO,TIME,SEX,INDIC_IL");
	* %_example_indic_fields(PNS11, rdb, FIELDS="GEO,TIME,INDIC_IL,SEX,HHTYP");

	%_example_indic_fields(OV9b1, rdb, FIELDS="GEO,TIME,AGE,SEX,UNIT,N_ITEM");
	%_example_indic_fields(OV9b2, rdb, FIELDS="GEO,TIME,AGE,SEX,UNIT");
					
	%_example_indic_fields(PEPS01, rdb, FIELDS="GEO,TIME,AGE,SEX,UNIT");
	%_example_indic_fields(PEPS02, rdb, FIELDS="GEO,TIME,AGE,SEX,WSTATUS");
	%_example_indic_fields(PEPS03, rdb, FIELDS="GEO,TIME,QUANTILE,HHTYP");
	%_example_indic_fields(PEPS04, rdb, FIELDS="GEO,TIME,AGE,SEX,ISCED97");
	%_example_indic_fields(PEPS05, rdb, FIELDS="GEO,TIME,AGE,SEX,CITIZEN");
	%_example_indic_fields(PEPS06, rdb, FIELDS="GEO,TIME,AGE,SEX,C_BIRTH");
	%_example_indic_fields(PEPS07, rdb, FIELDS="GEO,TIME,TENURE,UNIT");
	%_example_indic_fields(PEPS11, rdb, FIELDS="GEO,TIME,UNIT");
	%_example_indic_fields(PEPS60, rdb, FIELDS="GEO,TIME,AGE,ISCED97,UNIT");

	%_example_indic_fields(MDDD11, rdb, FIELDS="GEO,TIME,AGE,SEX,UNIT");
	%_example_indic_fields(MDDD12, rdb, FIELDS="GEO,TIME,AGE,SEX,WSTATUS");
	%_example_indic_fields(MDDD13, rdb, FIELDS="GEO,TIME,QUANTILE,HHTYP");
	%_example_indic_fields(MDDD14, rdb, FIELDS="GEO,TIME,AGE,SEX,ISCED97");
	%_example_indic_fields(MDDD15, rdb, FIELDS="GEO,TIME,AGE,SEX,CITIZEN");
	%_example_indic_fields(MDDD16, rdb, FIELDS="GEO,TIME,AGE,SEX,C_BIRTH");
	%_example_indic_fields(MDDD17, rdb, FIELDS="GEO,TIME,TENURE,UNIT");
	%_example_indic_fields(MDDD21, rdb, FIELDS="GEO,TIME,UNIT");
	%_example_indic_fields(MDDD60, rdb, FIELDS="GEO,TIME,AGE,ISCED97,UNIT");

	%_example_indic_fields(LVHL11, rdb, FIELDS="GEO,TIME,AGE,SEX,UNIT");
	%_example_indic_fields(LVHL12, rdb, FIELDS="GEO,TIME,AGE,SEX,WSTATUS");
	%_example_indic_fields(LVHL13, rdb, FIELDS="GEO,TIME,QUANTILE,HHTYP");
	%_example_indic_fields(LVHL14, rdb, FIELDS="GEO,TIME,AGE,SEX,ISCED97");
	%_example_indic_fields(LVHL15, rdb, FIELDS="GEO,TIME,AGE,SEX,CITIZEN");
	%_example_indic_fields(LVHL16, rdb, FIELDS="GEO,TIME,AGE,SEX,C_BIRTH");
	%_example_indic_fields(LVHL17, rdb, FIELDS="GEO,TIME,TENURE,UNIT");
	%_example_indic_fields(LVHL21, rdb, FIELDS="GEO,TIME,UNIT");
	%_example_indic_fields(LVHL60, rdb, FIELDS="GEO,TIME,AGE,ISCED97,UNIT");

	%_example_indic_fields(PEES01, rdb, FIELDS="GEO,TIME,AGE,SEX,INDIC_IL,UNIT");
	%_example_indic_fields(PEES02, rdb, FIELDS="GEO,TIME,WSTATUS,INDIC_IL");
	%_example_indic_fields(PEES03, rdb, FIELDS="GEO,TIME,QUANTILE,INDIC_IL");
	%_example_indic_fields(PEES04, rdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL");
	%_example_indic_fields(PEES05, rdb, FIELDS="GEO,TIME,ISCED97,INDIC_IL");
	%_example_indic_fields(PEES06, rdb, FIELDS="GEO,TIME,CITIZEN,INDIC_IL");
	%_example_indic_fields(PEES07, rdb, FIELDS="GEO,TIME,C_BIRTH,INDIC_IL");
	%_example_indic_fields(PEES08, rdb, FIELDS="GEO,TIME,TENURE,INDIC_IL,UNIT");

	%_example_indic_fields(mdho05, rdb, FIELDS="GEO,TIME,SEX,AGE,INCGRP,HHTYP,UNIT");
	%_example_indic_fields(mdho06a, rdb, FIELDS="GEO,TIME,SEX,AGE,INCGRP,UNIT");
	%_example_indic_fields(mdho06b, rdb, FIELDS="GEO,TIME,HHTYP,UNIT");
	%_example_indic_fields(mdho06c, rdb, FIELDS="GEO,TIME,TENURE,UNIT");
	%_example_indic_fields(mdho06d, rdb, FIELDS="GEO,TIME,DEG_URB,UNIT");
	%_example_indic_fields(mdho06q, rdb, FIELDS="GEO,TIME,QUANTILE,UNIT");

	%_example_indic_fields(lvho08a, rdb, FIELDS="GEO,TIME,SEX,AGE,INCGRP,UNIT");
	%_example_indic_fields(lvho08b, rdb, FIELDS="GEO,TIME,DEG_URB,UNIT");
	%_example_indic_fields(lvho07a, rdb, FIELDS="GEO,TIME,SEX,AGE,INCGRP,UNIT");
	%_example_indic_fields(lvho07b, rdb, FIELDS="GEO,TIME,QUANTILE,UNIT");
	%_example_indic_fields(lvho07c, rdb, FIELDS="GEO,TIME,TENURE,UNIT");
	%_example_indic_fields(lvho07d, rdb, FIELDS="GEO,TIME,DEG_URB,UNIT");
	%_example_indic_fields(lvho07e, rdb, FIELDS="GEO,TIME,HHTYP,UNIT");
	%_example_indic_fields(lvho05a, rdb, FIELDS="GEO,TIME,SEX,AGE,INCGRP,UNIT");
	%_example_indic_fields(lvho06, rdb, FIELDS="GEO,TIME,SEX,AGE,INCGRP,UNIT");
	%_example_indic_fields(lvho06q, rdb, FIELDS="GEO,TIME,QUANTILE,UNIT");
	%_example_indic_fields(lvho05b, rdb, FIELDS="GEO,TIME,HHTYP,UNIT");
	%_example_indic_fields(lvho05c, rdb, FIELDS="GEO,TIME,TENURE,UNIT");
	%_example_indic_fields(lvho05d, rdb, FIELDS="GEO,TIME,DEG_URB,UNIT");
	%_example_indic_fields(lvho05q, rdb, FIELDS="GEO,TIME,QUANTILE,UNIT");

	%_example_indic_fields(lvho15, rdb, FIELDS="GEO,TIME,SEX,AGE,citizen,UNIT");
	%_example_indic_fields(lvho16, rdb, FIELDS="GEO,TIME,SEX,AGE,c_birth,UNIT");
	%_example_indic_fields(lvho25, rdb, FIELDS="GEO,TIME,SEX,AGE,citizen,UNIT");
	%_example_indic_fields(lvho26, rdb, FIELDS="GEO,TIME,SEX,AGE,c_birth,UNIT");
	%_example_indic_fields(lvho27, rdb, FIELDS="GEO,TIME,SEX,INDIC_IL,UNIT");
	%_example_indic_fields(lvho28, rdb, FIELDS="GEO,TIME,TENURE,INDIC_IL,UNIT");
	%_example_indic_fields(lvho29, rdb, FIELDS="GEO,TIME,DEG_URB,INDIC_IL,UNIT");
	%_example_indic_fields(lvho30, rdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL,UNIT");

	%_example_indic_fields(lvho50a, rdb, FIELDS="GEO,TIME,AGE,SEX,INCGRP,UNIT");	
	%_example_indic_fields(lvho50b, rdb, FIELDS="GEO,TIME,QUANTILE,HHTYP,UNIT");		
	%_example_indic_fields(lvho50c, rdb, FIELDS="GEO,TIME,TENURE,UNIT");	
	%_example_indic_fields(lvho50d, rdb, FIELDS="GEO,TIME,DEG_URB,UNIT");	

	/* Test of dimensions for Early indicators */

	%_example_indic_fields(E_MDDD11, erdb, FIELDS="GEO,TIME,AGE,SEX,UNIT");
	%_example_indic_fields(E_MDDD13, erdb, FIELDS="GEO,TIME,HHTYP,QUANTILE");

	%_example_indic_fields(E_MDES01, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDES02, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDES03, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDES04, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDES05, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDES09, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,SUBJNMON,UNIT");

	%_example_indic_fields(E_MDDU01, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDDU02, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDDU03, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDDU04, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");
	%_example_indic_fields(E_MDDU05, erdb, FIELDS="GEO,TIME,HHTYP,INCGRP,UNIT");

	/* Test of dimensions for Longitudinal indicators */

	%_example_indic_fields(LVHL30, lrdb, FIELDS="GEO,TIME,SEX,WSTATUS,TRANS1Y");
	%_example_indic_fields(LVHL32, lrdb, FIELDS="GEO,TIME,SEX,WSTATUS,TRANS1Y");
	%_example_indic_fields(LVHL33, lrdb, FIELDS="GEO,TIME,SEX,WSTATUS,TRANS1Y");
	%_example_indic_fields(LVHL34, lrdb, FIELDS="GEO,TIME,QUANTILE,SEX,TRANS1Y");
	%_example_indic_fields(LVHL35, lrdb, FIELDS="GEO,TIME,SEX,WSTATUS,TRANS1Y");
	%_example_indic_fields(LI21, lrdb, FIELDS="GEO,TIME,SEX,AGE,INDIC_IL");
	%_example_indic_fields(LI23, lrdb, FIELDS="GEO,TIME,HHTYP,INDIC_IL,UNIT");
	%_example_indic_fields(LI24, lrdb, FIELDS="GEO,TIME,SEX,ISCED97,INDIC_IL,UNIT");
	%_example_indic_fields(LI51, lrdb, FIELDS="GEO,TIME,SEX,INDIC_IL,DURATION,UNIT");
	%_example_indic_fields(DI30a, lrdb, FIELDS="GEO,TIME,QUANTILE,TRANS1Y,UNIT");
	%_example_indic_fields(DI30b, lrdb, FIELDS="GEO,TIME,QUANTILE,TRANS2Y,UNIT");
	%_example_indic_fields(DI30c, lrdb, FIELDS="GEO,TIME,QUANTILE,TRANS3Y,UNIT");

	%if "&unmatchedField"="none" %then %do;
		%put all datasets fields matched;
	%end;
	%else %do;
		%put !!! List of (datasets,fields) not matched: &unmatchedField !!!;
		/* returns...
		 * for RDB indicators
			(DI10,unit), * CURRENCY (in RDB) is replaced by UNIT (on EUROBASE);
			(DI23,unit),
			(DI27,unit),
			(LI09b,unit),
			(LI10b,unit),
			(LI22b,unit),
			(LI60,unit),
			(LI41,unit),
			(IW15,unit),
			(IW16,unit),
			(PNP9,indic_il), * INDIC_IL with unique value LI_R_MD60 is added on EUROBASE;
			(OV9b2,unit),
			(PEPS07,unit),
			(PEPS11,unit),
			(PEPS60,unit),
			(MDDD17,unit),
			(MDDD21,unit),
			(MDDD60,unit),
			(LVHL17,unit),
			(LVHL21,unit),
			(LVHL60,unit),
			(PEES08,unit),
			(mdho05,unit),
			(mdho06a,unit),
			(mdho06b,unit),
			(mdho06c,unit),
			(mdho06d,unit),
			(mdho06q,unit),
			(lvho08a,unit),
			(lvho08b,unit),
			(lvho07a,unit),
			(lvho07b,unit),
			(lvho07c,unit),
			(lvho07d,unit),
			(lvho07e,unit),
			(lvho05a,unit),
			(lvho06,unit),
			(lvho06q,unit),
			(lvho05b,unit),
			(lvho05c,unit),
			(lvho05d,unit),
			(lvho05q,unit),
			(lvho15,unit),
			(lvho16,unit),
			(lvho25,unit),
			(lvho26,unit),
			(lvho27,unit),
			(lvho28,unit),
			(lvho29,unit),
			(lvho30,unit),
			(lvho50a,unit),
			(lvho50b,unit),
			(lvho50c,unit),
			(lvho50d,unit)
			* for Early indicators
			(E_MDES01,unit),
			(E_MDES02,unit),
			(E_MDES03,unit),
			(E_MDES04,unit),
			(E_MDES05,unit),
			(E_MDES09,unit),
			(E_MDDU01,unit),
			(E_MDDU02,unit),
			(E_MDDU03,unit),
			(E_MDDU04,unit),
			(E_MDDU05,unit)
			* for Longitudinal indicators
			(LI23,unit),
			(LI24,unit),
			(LI51,unit),
			(DI30a,unit),
			(DI30b,unit),
			(DI30c,unit)
			*/
	%end;

%mend _example_fields_to_list;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_fields_upload_rule;  
*/

/** \endcond */
