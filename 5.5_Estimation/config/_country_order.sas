/** 
## COUNTRY_ORDER {#cfg_country_order}
Provide the protocal order of EU countries.

### Contents
A table named after the value `&G_PING_COUNTRY_ORDER` (_e.g._, `COUNTRY_ORDER`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain the 
protocol order (_i.e._, order of dissemination in table) of EU+Non-EU countries. 

In practice, the table looks like this:
geo  | ORDER
-----|-------
EU28 |	0
EU27 |	0.1
EU25 |	0.2
EU15 |	0.3
NMS12|	0.4
NMS10|	0.5
EA19 |	0.6
EA18 |	0.7
EA17 |	0.8
EA16 |	0.9
BE   |	1
BG   |	2
CZ   |	3
DK   |	4
DE   |	5
EE   |	6
IE   |	7
EL   |	8
ES   |	9
FR   |	10
HR   |	11
IT   |	12
CY   |	13
LV   |	14
LT   |	15
LU   |	16
HU   |	17
MT   |	18
NL   |	19
AT   |	20
PL   |	21
PT   |	22
RO   |	23
SI   |	24
SK   |	25
FI   |	26
SE   |	27
UK   |	28
IS   |	29
NO   |	30
CH   |	31
MK   |	32
RS   |	33
TR   |	34

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%_country_order(cds_ctry_order=A, cfg=B, clib=C);

In order to generate the protocol order of countries only (without any mention to geographical areas),
it is necessary to set an additional keyword parameter:

	%_country_order(cds_ctry_order=A, cfg=B, clib=C, zone=no);

Note that, by default, the command `%%_country_order;` runs:

	%_country_order(cds_ctry_order=&G_PING_COUNTRY_ORDER, 
					cfg=&G_PING_ESTIMATION/config, 
					clib=&G_PING_LIBCFG, zone=yes);

### Example
Generate the table `COUNTRY_ORDER` in the `WORK` directory:

	%_country_order(clib=WORK);

### Reference
Eurostat _Statistics Explained_ [webpage](http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:Protocol_order) 
on protocol order and country code.

### See also
[%str_isgeo](@ref sas_str_isgeo).
*/ /** \cond */


%macro _country_order(cds_ctry_order=, cfg=, clib=, zone=yes);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(cds_ctry_order) %then %do;
		%if %symexist(G_PING_COUNTRY_ORDER) %then 	%let cds_ctry_order=&G_PING_COUNTRY_ORDER;
		%else										%let cds_ctry_order=COUNTRY_ORDER;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_ESTIMATION) %then 		%let cfg=&G_PING_ESTIMATION/config;
		%else										%let cfg=&G_PING_ROOTPATH/5.5_Estimation/config;
	%end;

	%local l_GEO FMT_CODE;
	%if %symexist(G_PING_FMT_CODE) %then 		%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=csv;
	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* option 1:
	%file_import(&cds_ctry_order, fmt=&FMT_CODE, _ods_=&cds_ctry_order, 
				idir=&cfg, olib=&clib, getnames=yes); 
	*/

	/*option 2:
	PROC IMPORT OUT=&cds_ctry_order
	    DATAFILE="&cfg/&cds_ctry_order..&FMT_CODE"
	    DBMS=&FMT_CODE		
		%if %sysfunc(exist(&cds_ctry_order)) %then %do;
			REPLACE
		%end;
		;
	    GETNAMES=YES;
	run;
	DATA &clib..&cds_ctry_order(drop=order_old);
		retain &l_GEO ORDER;
		length ORDER 8;
		set &cds_ctry_order(rename = (ORDER=order_old));
		ORDER=order_old;
	run;*/

	/* option 3 */
	%local _tmp n0;
	%let _tmp=TMP&sysmacroname;

	%if %upcase("&zone")="YES" %then 		%let n0=1;
	%else %if %upcase("&zone")="NO"	%then	%let n0=11;


	DATA &_tmp;
		array geos{44} $5 _TEMPORARY_ ('EU28','EU27','EU25','EU15','NMS12','NMS10','EA19','EA18','EA17','EA16','BE','BG','CZ','DK','DE','EE','IE','EL','ES','FR','HR','IT','CY','LV','LT','LU','HU','MT','NL','AT','PL','PT','RO','SI','SK','FI','SE','UK','IS','NO','CH','MK','RS','TR');
		array orders{44} _TEMPORARY_  (     0,   0.1,   0.2,   0.3,    0.4,    0.5,   0.6,   0.7,   0.8,   0.9,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,  32,  33,  34);
		do n = &n0 to 44;
			&l_GEO = geos{n};
			ORDER = orders{n};
			output;
		end;
		drop n;
	run;

	DATA &clib..&cds_ctry_order;
		set &_tmp;
	run;

	%work_clean(&_tmp);
%mend _country_order;


%macro _example_country_order;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create the table &G_PING_COUNTRY_ORDER with list of ordered geographic zones + countries in WORK library; 
	%_country_order(clib=WORK);
	%ds_print(&G_PING_COUNTRY_ORDER);

	%put;
	%put (ii) Ibid, with list of ordered countries only; 
	%_country_order(clib=WORK, zone=NO);
	%ds_print(&G_PING_COUNTRY_ORDER);

	%work_clean(&G_PING_COUNTRY_ORDER);

	%put;
%mend _example_country_order;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_country_order;
*/

/** \endcond */
