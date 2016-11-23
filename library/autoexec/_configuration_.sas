/** \cond */

/* Macros creating the metadata files where the indicator names are encoded. 

Arguments

Outputs
Creates the codes_indicators_*.sas7bdat datasets stored in SILCFMT and where indicator 
names are encoded.
*/ 

%macro _default_import_indicator_codes_;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local v_indicator_codes_rdb v_indicator_codes_rdb2 v_indicator_codes_edb v_indicator_codes_ldb;

	%if %symexist(G_PING_SILCLIBCFG) %then 			%let SILCLIBCFG=&G_PING_SILCLIBCFG;
	%else										%let SILCLIBCFG=SILCFMT;
	%if %symexist(G_PING_SILCLIBDATA) %then 			%let SILCLIBDATA=&G_PING_SILCLIBDATA;
	%else										%let SILCLIBDATA=&EUSILC/library/data ;
			
	%if %symexist(G_PING_FMT_CODE) %then 			%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=CSV;

	%if %symexist(G_PING_INDICATOR_CODES_RDB) %then 	%let v_indicator_codes_rdb=&G_PING_INDICATOR_CODES_RDB;
	%else										%let v_indicator_codes_rdb=INDICATOR_CODES_RDB;
	/* PROC IMPORT OUT=&SILCLIBCFG..&v_indicator_codes_rdb
	    DATAFILE="&SILCLIBDATA/&v_indicator_codes_rdb..&FMT_CODE"
	    DBMS=&FMT_CODE		
		%if %sysfunc(exist(&SILCLIBCFG..&v_indicator_codes_rdb)) %then %do;
			REPLACE
		%end;
		;
	    GETNAMES=YES;
	RUN; */
	%file_import(&v_indicator_codes_rdb, &FMT_CODE, _ds_=&v_indicator_codes_rdb, 
				idir=&SILCLIBDATA, olib=&SILCLIBCFG, getnames=yes, import=yes);

	/* DATA &G_PING_INDICATOR_CODES_RDB;
	    LENGTH
	        indicator        $ 25 ;
	    FORMAT
	        indicator        $CHAR25. ;
	    INFORMAT
	        indicator        $CHAR25. ;
	    INFILE "&SILCLIBDATA/&v_indicator_codes_rdb.&G_PING_FMT_CODE"
			FIRSTOBS=2
	        LRECL=25
	        ENCODING="LATIN1"
	        TERMSTR=CRLF
	        DLM='7F'x
	        MISSOVER
	        DSD ;
	    INPUT
	        indicator        : $CHAR25. ;
	RUN; */

	%if %symexist(G_PING_INDICATOR_CODES_RDB2) %then %let v_indicator_codes_rdb2=&G_PING_INDICATOR_CODES_RDB2;
	%else										%let v_indicator_codes_rdb2=INDICATOR_CODES_RDB2;
	/* PROC IMPORT OUT=&SILCLIBCFG..&v_indicator_codes_rdb2
	    DATAFILE="&SILCLIBDATA/&indicator_codes_rdb2..&FMT_CODE"
	    DBMS=&FMT_CODE 
		%if %sysfunc(exist(&SILCLIBCFG..&v_indicator_codes_rdb2)) %then %do;
			REPLACE
		%end;
		;
	    GETNAMES=YES;
	RUN; */
	%file_import(&v_indicator_codes_rdb2, &FMT_CODE, _ds_=&v_indicator_codes_rdb2, 
				idir=&SILCLIBDATA, olib=&SILCLIBCFG, getnames=yes, import=yes);

	%if %symexist(G_PING_INDICATOR_CODES_EDB) %then 	%let v_indicator_codes_edb=&G_PING_INDICATOR_CODES_EDB;
	%else										%let v_indicator_codes_edb=INDICATOR_CODES_EDB;
	/* PROC IMPORT OUT=&SILCLIBCFG..&v_indicator_codes_edb
	    DATAFILE="&SILCLIBDATA/&v_indicator_codes_edb..&FMT_CODE"
	    DBMS=&FMT_CODE 
		%if %sysfunc(exist(&SILCLIBCFG..&v_indicator_codes_edb)) %then %do;
			REPLACE
		%end;
		;
	    GETNAMES=YES;
	RUN; */
	%file_import(&v_indicator_codes_edb, &FMT_CODE, _ds_=&v_indicator_codes_edb, 
				idir=&SILCLIBDATA, olib=&SILCLIBCFG, getnames=yes, import=yes);

	%if %symexist(G_PING_INDICATOR_CODES_LDB) %then 	%let v_indicator_codes_ldb=&G_PING_INDICATOR_CODES_LDB;
	%else										%let v_indicator_codes_ldb=INDICATOR_CODES_LDB;
	/* PROC IMPORT OUT=&SILCLIBCFG..&v_indicator_codes_ldb
	    DATAFILE="&SILCLIBDATA/&v_indicator_codes_ldb..&FMT_CODE"
	    DBMS=&FMT_CODE 
		%if %sysfunc(exist(&SILCLIBCFG..&v_indicator_codes_ldb)) %then %do;
			REPLACE
		%end;
		;
	    GETNAMES=YES;
	RUN; */
	%file_import(&v_indicator_codes_ldb, &FMT_CODE, _ds_=&v_indicator_codes_ldb, 
				idir=&SILCLIBDATA, olib=&SILCLIBCFG, getnames=yes, import=yes);

%mend _default_import_indicator_codes_;

%macro _default_import_ctry_order_;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local v_geo v_country_order;

	%if %symexist(G_PING_SILCLIBCFG) %then 			%let SILCLIBCFG=&G_PING_SILCLIBCFG;
	%else										%let SILCLIBCFG=SILCFMT;

	%if %symexist(G_PING_COUNTRY_ORDER) %then 	%let v_country_order=&G_PING_COUNTRY_ORDER;
	%else									%let v_country_order=COUNTRY_ORDER;

	%if %symexist(G_PING_VAR_GEO) %then 				%let v_geo=&G_PING_VAR_GEO;
	%else										%let v_geo=GEO;

	/* option 1:
	%file_import(&v_country_order, &FMT_CODE, _ds_=&v_country_order, 
				idir=&SILCLIBDATA, olib=&SILCLIBCFG, getnames=yes, import=yes); 
	*/

	/*option 2:
	PROC IMPORT OUT=&v_country_order
	    DATAFILE="&SILCLIBDATA/&v_country_order..&FMT_CODE"
	    DBMS=&FMT_CODE		
		%if %sysfunc(exist(&v_country_order)) %then %do;
			REPLACE
		%end;
		;
	    GETNAMES=YES;
	run;
	DATA &SILCFMT..&v_country_order(drop=order_old);
		retain GEO ORDER;
		length ORDER 8;
		set &v_country_order(rename = (ORDER=order_old));
		ORDER=order_old;
	run;*/

	/* option 3 */
	%local TMP;
	%let TMP=_tmp_country_order_update;
	DATA &TMP;
		array geos{44} $5 _TEMPORARY_ ('EU28','EU27','EU25','EU15','NMS12','NMS10','EA19','EA18','EA17','EA16','BE','BG','CZ','DK','DE','EE','IE','EL','ES','FR','HR','IT','CY','LV','LT','LU','HU','MT','NL','AT','PL','PT','RO','SI','SK','FI','SE','UK','IS','NO','CH','MK','RS','TR');
		array orders{44} _TEMPORARY_  (     0,   0.1,   0.2,   0.3,    0.4,    0.5,   0.6,   0.7,   0.8,   0.9,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,  32,  33,  34);
		drop n;
		do n = 1 to 44;
			&v_geo = geos{n};
			ORDER = orders{n};
			output;
		end;
	run;

	DATA &SILCLIBCFG..&v_country_order;
		set &TMP;
	run;

	%work_clean(&TMP);
	
%mend _default_import_ctry_order_;



%macro _default_import_currency_zones_;
;
%mend _default_import_currency_zones_;

%macro _default_import_;
	%_default_import_indicator_codes_;
	%_default_import_ctry_order_;
	%_default_import_ctry_population_;
	%_default_import_ctry_zones_; 
%mend _default_import_;

/** \endcond */
