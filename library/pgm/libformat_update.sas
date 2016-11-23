/* Create libref format:libref.formats  

Syntax (single step)
    - create formats catalog : using proc catalog 
	- list of contents       : using    cntlout  option to proc catalog :  to have the characteristic  of each format created 
   	- option to add each program to search  the formats:  first in catalog after in work area
 	- modify the  formats:  add  the  description to each format 
	- to copy formats catalog in SILCFMT library

Inputs
- format for each variables 

Example:
if you create a libref called "catalog" your formats would be stored in "catalog.formats"
  
Note
----

*/

%global SASMain;
%let SASMain=/ec/prod/server/sas;
%let LIBRARY=&SASMain/0eusilc/library; 
libname catalog "&LIBRARY/catalog";

/* 1. create formats catalog : using proc catalog  */
PROC FORMAT library=catalog.formats.age;

  	VALUE fmt1_age (multilabel notsorted)
		16 - 19 = "Y16-19"
		16 - 24 = "Y16-24"
		16 - 29 = "Y16-29"
		15 - 19 = "Y15-19"
		15 - 24 = "Y15-24"
		15 - 29 = "Y15-29"
		20 - 24 = "Y20-24"
		20 - 29 = "Y20-29"
		25 - 29 = "Y25-29"   
 		18 - HIGH = "Y_GE18"
		18 - 64 = "Y18-64"
		65 - HIGH = "Y_GE65"
		18 - 24 = "Y18-24"
		25 - 54 = "Y25-54"
		55 - 64 = "Y55-64";
	VALUE fmt2_age  (multilabel notsorted)
	    0-15= "Y_LT16"
		16-24 = "Y16_24"
		25-49 = "Y25_49"
		50-64 = "Y50_64"
		65-high= "Y_GE65";

   VALUE fmt3_age (multilabel)
		LOW - 64 = "A1_LT65"
		65 - HIGH = "A1_GE65";


	VALUE fmt4_age (multilabel)
		18 - HIGH = "Y_GE18"
		18 - 74 = "Y18-74"
		18 - 24 = "Y18-24"
		18 - 64 = "Y18-64"
		18 - 59 = "Y18-59"
		25 - 49 = "Y25-49"
		25 - 59 = "Y25-59"
		50 - 64 = "Y50-64"
		50 - 59 = "Y50-59"
		65 - 74 = "Y65-74"
		65 - HIGH = "Y_GE65"
		75 - HIGH = "Y_GE75"
		60 - HIGH = "Y_GE60"
		25 - 54 = "Y25-54"
		55 - HIGH = "Y_GE55";
run;
PROC FORMAT library=catalog.formats ;	
  	VALUE fmt1_sex (multilabel notsorted)
		1 , 2 = "TOTAL"
		1 = "MALE"
		2 = "FEMALE";

	VALUE fmt1_ht (multilabel)
 	  	5 - 8 = "HH_NDCH"
		5 =	 "A1" 
		6 =	 "A2_2LT65"
		7 =	 "A2_GE1_GE65"
		6,7 = "A2"
		8 =	 "A_GE3"
		6 - 8 = "A_GE2_NDCH"
		9 - 13 = "HH_DCH"
		9 =	 "A1_DCH"
		10 = "A2_1DCH"
		10 - 13 = "A_GE2_DCH"
		11 = "A2_2DCH"
		12 = "A2_GE3DCH"
		13 = "A_GE3_DCH"
		5 - 13 = "TOTAL";

	VALUE fmt1_educ (multilabel)
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5-8"
		0 - 6 = "TOTAL";
	VALUE fmt1_act (multilabel)

		1 - 4 = "EMP" /* 1 filled only up to 2008 included, 2,3,4 filled only from 2009 no overlapping*/
		2 = "SAL"
		3 = "NSAL";
 
	VALUE fmt2_act (multilabel)

		1 - 4 = "EMP" /* 1 filled only up to 2008 included, 2,3,4 filled only from 2009 no overlapping*/
		2 = "SAL"
		3 = "NSAL"  
		5 = "UNE"
		6 = "RET"
		7 = "INAC_OTH"
		5 - 8 = "NEMP"
		1 - 8 = "POP";
	VALUE fmt1_educ (multilabel)
		0 - 2 = "ED0-2"
		3 - 4 = "ED3_4"
		5 - 6 = "ED5-8"
	 	0 - 6 = "TOTAL" ;

run;
data catalog.format;
  set ASSO_DICO_FORMATS;
run; 
/* step 2. - list of contents :   "cntlout"  option :  to have format description */

proc format library=catalog  cntlout=fmt;

run;
proc catalog catalog=catalog.format;
contents;

run;
data fmt (keep=fmtname start end label);set fmt;run;

/* 3. Step	- option to add to  the  program to search  the formats:  first searchs in catalog after in work area */
 	
option nofmterr fmtsearch=(catalog.formats work.formats ) nodate;   

/* 4. step - modify the  formats:  add  the  description to each format */
/*

proc catalog catalog=catalog.formats;
 
  modify fmt14_ht (description="A1_DCH HH_DCH A2_1DCH A2_2DCH A_GE2_DCH TOTAL")/ et=format;
  modify fmt14_age (description="Y_LT16 Y16_24 Y25_49 Y50_64 Y_GE65")/ et=format;
  modify fmt_age (description="Y16_24 Y25_49 Y50_64 Y_GE65")/ et=format;
  modify fmt_quantile  (description="QUINTILE1 QUINTILE2 QUINTILE3 QUINTILE4 QUINTILE5 TOTAL")/ et=format;
  modify fmt_DEG_URB(description="DEG1 DEG2 DEG3 TOTAL")/ et=format;
  modify fmt_ht (description="HH_NDCH A1 A2 HH_DCH A_GE3 TOTAL")/ et=format;
  modify fmt_sex(description="TOTAL MALE FEMALE")/ et=format;
  contents;
run; 
  
proc catalog catalog=catalog.formats;
  contents;
run;
/* 5. step - to copy formats catalog in SILCFMT library  */
/*
data SILCFMT.CODE_FORMATS(keep=name desc);set CODE_FORMATS;
where type='FORMAT';
run;	 
