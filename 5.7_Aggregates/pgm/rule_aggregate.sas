/**
# rule_aggregate {#sas_rule_aggregate}

	%rule_aggregate(ind, fields, _fields_=);
*/ /** \cond */

%macro rule_aggregate(/*input*/  ind, fields);
	%let Uind=%upcase(&ind);

	%local _fields;
	/* remove occurences of both fields */
	%let _fields=%list_remove(%list_remove(&fields, geo), time);

	/* fields adjusted for RDB indicators */
	%if &Uind=DI02 or &Uind=DI03 or &Uind=DI04 or &Uind=DI05 or &Uind=DI07 or &Uind=DI08 or &Uind=DI09 or 
		&Uind=DI10 or &Uind=DI11 or &Uind=DI12 or &Uind=DI12B or &Uind=DI12C or &Uind=DI13 or &Uind=DI13B or 
		&Uind=DI14 or &Uind=DI14B or &Uind=DI15 or &Uind=DI16 or &Uind=DI17 or &Uind=DI20 or &Uind=DI23 or &Uind=DI27 or
 		&Uind=IW01 or &Uind=IW02 or &Uind=IW03 or &Uind=IW04 or &Uind=IW05 or &Uind=IW06 or &Uind=IW07 or &Uind=IW15 or &Uind=IW16 or
 		&Uind=LI01 or &Uind=LI02 or &Uind=LI03 or &Uind=LI04 or &Uind=LI06 or &Uind=LI07 or &Uind=LI08 or &Uind=LI09 or &Uind=LI09B or 
		&Uind=LI10 or &Uind=LI10B or &Uind=LI11 or &Uind=LI22 or &Uind=LI22A or &Uind=LI22B or &Uind=LI31 or &Uind=LI32 or &Uind=LI41 or 
		&Uind=LI45 or &Uind=LI48 or &Uind=LI60 or
 		&Uind=LVHL11 or &Uind=LVHL12 or &Uind=LVHL13 or &Uind=LVHL14 or &Uind=LVHL15 or &Uind=LVHL16 or &Uind=LVHL17 or &Uind=LVHL21 or 
		&Uind=LVHL60 or &Uind=LVHO05_06 or &Uind=LVHO05Q_06Q or &Uind=LVHO07 or &Uind=LVHO08 or &Uind=LVHO15 or &Uind=LVHO16 or
 		&Uind=LVHO25 or &Uind=LVHO26 or &Uind=LVHO27_30 or &Uind=LVHO50 or
		&Uind=MDDD11 or &Uind=MDDD12 or &Uind=MDDD13 or &Uind=MDDD14 or &Uind=MDDD15 or &Uind=MDDD16 or &Uind=MDDD17 or &Uind=MDDD21 or 
		&Uind=MDDD60 or
		&Uind=MDHO05 or &Uind=MDHO06 or &Uind=MDHO06Q or &Uind=OV9B or
		&Uind=PEES01 or &Uind=PEES02 or &Uind=PEES03 or &Uind=PEES04 PEES05 PEES06 or &Uind=PEES07 or &Uind=PEES08 or
		&Uind=PEPS01 or &Uind=PEPS02 or &Uind=PEPS03 or &Uind=PEPS04 or &Uind=PEPS05 or &Uind=PEPS06 or &Uind=PEPS07 or &Uind=PEPS11 or 
		&Uind=PEPS60 or
		&Uind=PNP10 or &Uind=PNP2 or &Uind=PNP3 or &Uind=PNP9
			%then %do; /* UNIT is added on aggregate fields */
		%let _fields=&_fields unit;
	%end;

	/* fields adjusted for Early indicators */

	/* dimensions adjusted for Longitudinal indicators */

	/*  we return it  
	%quote(&grpdim)*/

	&_fields
%mend rule_aggregate;


%macro _example_rule_aggregate;
	%if %symexist(EUSILC) EQ 0 %then %do; 
		%include "/ec/prod/server/sas/0eusilc/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* libname ex_data "&library/data"; /* ex_data is SILCFMT! */
	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB/C_RDB"; */ 
	libname rdb2 "&G_PING_C_RDB2"; 
	libname e_rdb "&G_PING_E_RDB"; 
	libname l_rdb "&G_PING_L_RDB"; 

	%local dimcol dimcolC;

	/* test RDB indicators */

	%let tab=DI02;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (i)   for RDB indicator &tab; 
	%put res:  output by fields_to_list are dimcol=&dimcol;
	%rule_aggregate(&tab, %quote(&dimcol), _fields_=dimcol);
	/* %list_quote(&dimcol, _clist_=dimcol);
	%clist_unquote(&dimcol, _list_=dimcol, sep=%str(%"), rep=%str(,)); */
	%put res:  updated fields is &dimcol;
/*
    %let tab=DI14b;
    %fields_to_list(&tab, lib=rdb, _list_=dimcol);
    %put (ii) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%rule_aggregate(&tab, %quote(&dimcol));
    %put res:  updated dimensions are &dimcol;

	%let tab=LI03;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (iii) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%rule_aggregate(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol;

	%let tab=IW07;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (iv) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%rule_aggregate(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);

	%let tab=LI48;
	%fields_to_list(&tab, lib=rdb, _list_=dimcol);
	%put (v) for RDB indicator=&tab and dimcol="&dimcol" output by fields_to_list;
	%let dimcol=%rule_aggregate(&tab, %quote(&dimcol));
	%put res:  updated dimensions are &dimcol (no change);
*/
	/* test RDB2 indicators */

	/* test Early indicators */

	/* test Longitudinal indicators */


%mend _example_rule_aggregate;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_rule_aggregate;  
*/


%macro test;
%if &Utab=DI02 %then %do;
	%let grpdim= incgrp,indic_il,currency,unit ;
%end; 
%else %if &Utab=DI03 %then %do;
	%let grpdim= age,sex,indic_il,unit ;
%end; 
%else %if &Utab=DI04 %then %do;
	%let grpdim=hhtyp,indic_il,unit;
%end; 
%else %if &Utab=DI05 %then %do;
        %let grpdim=wstatus,age,sex,indic_il,unit;
%end; 
%else %if &Utab=DI07 %then %do;
        %let grpdim=hhtyp,workint,age,sex,indic_il,unit;
%end; 
%else %if &Utab=DI08 %then %do;
        %let grpdim=age,sex,isced11,indic_il,unit;
%end; 
%else %if &Utab=DI09 %then %do;
        %let grpdim=age,sex,tenure,indic_il,unit;
%end; 
%else %if &Utab=DI10 %then %do;
        %let grpdim= indic_il,subjnmon,currency,unit ;
%end; 
%else %if &Utab=DI13 %then %do;
        %let grpdim=age,sex,indic_il,unit;
%end; 
%else %if &Utab=DI13b %then %do;
        %let grpdim=hhtyp,indic_il,unit;
%end; 
%else %if &Utab=DI14 %then %do;
	%let grpdim=age,sex,indic_il,unit;
%end; 
%else %if &Utab=DI14b %then %do;
        %let grpdim=hhtyp,indic_il,unit;
%end; 
%else %if &Utab=DI15 %then %do;
        %let grpdim= age,sex,citizen,indic_il,unit ;
%end; 
%else %if &Utab=DI16 %then %do;
        %let grpdim= age,sex,c_birth,indic_il,unit ;
%end; 
%else %if &Utab=DI17 %then %do;
        %let grpdim=age,sex,deg_urb,indic_il,unit;
%end; 
%else %if &Utab=IW01 %then %do;
        %let grpdim=age,sex ,wstatus,unit;
%end; 
%else %if &Utab=IW02 %then %do;
        %let grpdim=hhtyp,unit;
%end; 
%else %if &Utab=IW03 %then %do;
        %let grpdim=hhtyp,workint,unit;
%end;
%else %if &Utab=IW04 %then %do;
        %let grpdim=isced11,unit;
%end; 
%else %if &Utab=IW05 %then %do;
        %let grpdim=wstatus,sex,unit;
%end; 
%else %if &Utab=IW06 %then %do;
        %let grpdim=duration,unit;
%end; 
%else %if &Utab=IW07 %then %do;
        %let grpdim=worktime,unit;
%end; 
%else %if &Utab=IW15 %then %do;
    %let grpdim=age,sex ,citizen,unit;
%end; 
%else %if &Utab=IW16 %then %do;
    %let grpdim=age,sex ,c_birth,unit;
%end; 
%else %if &Utab=LI02 %then %do;
    %let grpdim=age,sex ,indic_il,unit;
%end; 
%else %if &Utab=LI03 %then %do;
    %let grpdim=hhtyp,indic_il,unit;
%end; 
%else %if &Utab=LI04 %then %do;
    %let grpdim=wstatus,age,sex,indic_il,unit;
%end; 
%else %if &Utab=LI06 %then %do;
    %let grpdim=indic_il,age,sex,hhtyp,workint,unit;
%end; 
%else %if &Utab=LI07 %then %do;
	%let grpdim=age,sex,isced11,indic_il,unit;
%end;
%else %if &Utab=LI08 %then %do;
    %let grpdim=TENURE,indic_il,age,sex,unit;
%end; 
%else %if &Utab=LI09 %then %do;
    %let grpdim=age,sex,indic_il,unit;
%end; 
%else %if &Utab=LI09b %then %do;
    %let grpdim=hhtyp,unit;
%end; 
%else %if &Utab=LI10 %then %do;
    %let grpdim=age,sex,indic_il,unit;
%end; 
%else %if &Utab=LI10b %then %do;
    %let grpdim=hhtyp,unit;
%end; 
%else %if &Utab=LI22 %then %do;
    %let grpdim=age, sex, indic_il, unit;
%end; 
%else %if &Utab=LI22_anybase %then %do;
    %let grpdim=age, sex, anchor, unit;
%end; 
%else %if &Utab=LI22b %then %do;
    %let grpdim=age, sex, indic_il, unit;
%end; 
%else %if &Utab=LI22b_backwards %then %do;
    %let grpdim=age, sex, indic_il, unit;
%end; 
%else %if &Utab=LI31 %then %do;
	%let grpdim=age, sex, citizen, unit;
%end;
%else %if &Utab=LI32 %then %do;
	%let grpdim=age, sex, c_birth, unit;
%end; 
%else %if &Utab=LI45 %then %do;
	%let grpdim=age,sex,unit;
%end; 
%else %if &Utab=LI48 %then %do;
	%let grpdim=DEG_URB,unit;
%end; 
%else %if &Utab=LI60 %then %do;
    %let grpdim=age,isced11 ,unit;
%end;
%else %if &Utab=LVHL11 %then %do;
	%let grpdim=age, sex, unit;
%end; 
%else %if &Utab=LVHL12 %then %do;
	%let grpdim=age, sex, wstatus, unit;
%end; 
%else %if &Utab=LVHL13 %then %do;
	%let grpdim= quantile, hhtyp, unit;
%end; 
%else %if &Utab=LVHL14 %then %do;
	%let grpdim=age, sex, isced11, unit;
%end; 
%else %if &Utab=LVHL15 %then %do;
	%let grpdim=age, sex, citizen, unit;
%end; 
%else %if &Utab=LVHL16 %then %do;
	%let grpdim=age, sex, c_birth, unit;
%end; 
%else %if &Utab=LVHL17 %then %do;
	%let grpdim= tenure,  unit;
%end; 
%else %if &Utab=LVHL60 %then %do;
    %let grpdim=age,isced11 ,unit;
%end; 
%else %if &Utab=LVHO05_06 %then %do;
	%let grpdim=age, sex, incgrp, unit;
	%let grpdim=age, sex, incgrp, unit;
	%let grpdim=HHTYP, unit;
	%let grpdim=TENURE, unit;
	%let grpdim=DEG_URB, unit;
%end; 
%else %if &Utab=LVHO05q_06q %then %do;
    %let grpdim=quantile, unit;
    %let grpdim=quantile, unit;
%end;
%else %if &Utab=LVHO07 %then %do;
    %let grpdim=age, sex, incgrp, unit;
    %let grpdim=QUANTILE, unit;
    %let grpdim=TENURE, unit;
    %let grpdim=DEG_URB, unit;
    %let grpdim=HHTYP, unit;
%end; 
%else %if &Utab=LVHO08 %then %do;
    %let grpdim=age, sex, incgrp, unit;
    %let grpdim=DEG_URB, unit;
%end;
%else %if &Utab=LVHO15 %then %do;
    %let grpdim=age,sex ,citizen,unit;
%end;
%else %if &Utab=LVHO16 %then %do;
    %let grpdim=age,sex ,c_birth,unit;
%end; 
%else %if &Utab=LVHO25 %then %do;
    %let grpdim=age, sex, citizen, unit;
%end; 
%else %if &Utab=LVHO26 %then %do;
    %let grpdim=age, sex, c_birth, unit;
%end; 
%else %if &Utab=LVHO27_30 %then %do;
	%let grpdim=TENURE, indic_il,unit;
    %let grpdim=sex, indic_il, unit;
    %let grpdim=DEG_URB, indic_il,unit;
    %let grpdim=HHTYP,indic_il, unit;
%end; 
%else %if &Utab=LVHO50 %then %do;
	%let grpdim=age, sex, incgrp, unit;
	%let grpdim=quantile, hhtyp, unit;
	%let grpdim=tenure, unit;
	%let grpdim=deg_urb, unit;
%end; 
%else %if &Utab=MDDD11 %then %do;
%let grpdim=age, sex, unit;
%end; 
%else %if &Utab=MDDD12 %then %do;
	%let grpdim= sex, age, wstatus, unit;
%end; 
%else %if &Utab=MDDD13 %then %do;
	%let grpdim= quantile, hhtyp, unit;
%end; 
%else %if &Utab=MDDD14 %then %do;
	%let grpdim= sex, age, isced11, unit;
%end; 
%else %if &Utab=MDDD15 %then %do;
	%let grpdim= sex, age, citizen, unit;
%end; %else %if &Utab=MDDD16 %then %do;
	%let grpdim= sex, age, c_birth, unit;
%end; 
%else %if &Utab=MDDD17 %then %do;
	%let grpdim= tenure, unit;
%end; 
%else %if &Utab=MDDD60 %then %do;
    %let grpdim=age,isced11 ,unit;
%end; 
%else %if &Utab=MDHO05 %then %do;
	%let grpdim=age, sex, incgrp, HHTYP, unit;
%end; 
%else %if &Utab=MDHO06 %then %do;
	%let grpdim=age, sex, incgrp, unit;
	%let grpdim=HHTYP, unit;
	%let grpdim=TENURE, unit;
	%let grpdim=DEG_URB, unit;
%end; 
%else %if &Utab=MDHO06q %then %do;
        %let grpdim=quantile, unit;
%end; 
%else %if &Utab=OV9b %then %do;
	%let grpdim=age, sex, unit, n_item;
	%let grpdim=age, sex, unit;
%end; 
%else %if &Utab=PEES01 %then %do;
	%let grpdim=age, sex, indic_il, unit;
%end; 
%else %if &Utab=PEES02 %then %do;
	%let grpdim= wstatus , indic_il,unit ;
%end;
%else %if &Utab=PEES03 %then %do;
	%let grpdim=   quantile,indic_il,unit;
%end; 
%else %if &Utab=PEES04 %then %do;
	%let grpdim= hhtyp, indic_il, unit ;
%end; 
%else %if &Utab=PEES05 %then %do;
	%let grpdim= isced11,indic_il, unit ;
%end; 
%else %if &Utab=PEES06 %then %do;
	%let grpdim= citizen,indic_il, unit ;
%end; 
%else %if &Utab=PEES07 %then %do;
	%let grpdim= c_birth,indic_il,  unit;
%end; 
%else %if &Utab=PEES08 %then %do;
	%let grpdim=   tenure,indic_il,unit;
%end; 
%else %if &Utab=PEPS01 %then %do;
	%let grpdim=age, sex, unit;
	%let grpdim= unit;
%end; 
%else %if &Utab=PEPS02 %then %do;
	%let grpdim=age, sex, wstatus, unit;
%end; 
%else %if &Utab=PEPS03 %then %do;
	%let grpdim= quantile, hhtyp, unit;
%end; 
%else %if &Utab=PEPS04 %then %do;
	%let grpdim=age, sex, isced11, unit;
%end; 
%else %if &Utab=PEPS05 %then %do;
	%let grpdim=age, sex, citizen, unit;
%end; 
%else %if &Utab=PEPS06 %then %do;
	%let grpdim=age, sex, c_birth, unit;
%end; 
%else %if &Utab=PEPS07 %then %do;
	%let grpdim=tenure, unit;
%end; 
%else %if &Utab=PEPS60 %then %do;
        %let grpdim=age,isced11 ,unit;
%end;
%mend;

/** \endcond */
