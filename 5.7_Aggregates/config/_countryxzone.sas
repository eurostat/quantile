/** 
## COUNTRYxZONE {#cfg_countryxzone}
Configuration file for correspondance between countries and geographical areas.

### Contents
A table named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain for 
every country in the EU+EFTA geographic area:
* its year of entrance in, and
* its year of exit of (when such case applies) 

any given euro zone (_e.g._, eurozones EA18, EA19, EU27, EU28 + EFTA). 

In practice, the table looks like this:
geo |  EA  | EA12 | EA13 | EA16 | EA17 | EA18 | EA19 | EEA  | EEA18| EEA28| EEA30| EU15 | EU25 | EU27 | EU28 | EFTA | EU07 | EU09 | EU10 | EU12 
----|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------
AT  | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1994 | 1994 | 1994 | 1994 | 1995 | 1995 | 1995 | 1995 | 1960 |   .  |   .  |   .  |   .
AT  | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 1995 |   .  |   .  |   .  |   .
BE  | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1994 | 1994 | 1994 | 1994 | 1957 | 1957 | 1957 | 1957 |   .  | 1957 | 1957 | 1957 | 1957
BE  | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 |   .  | 2500 | 2500 | 2500 | 2500
... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... 

### Creation and update
Consider an input CSV table called `A.csv`, with the following structure (where all areas/observations 
considered under `ZONE` are the areas/variables - uniquely - reported in the table above):
geo | COUNTRY|	ZONE | YEAR_IN | YEAR_OUT 
----|--------|-------|---------|----------
AT	|Austria|	EA	 |  1999   |  2500
AT	|Austria|	EA12 |  1999   |  2500
AT	|Austria|	EA13 |  1999   |  2500
AT	|Austria|	EA16 |  1999   |  2500
... |  ...  |   ...  |   ...   |  ...
AT	|Austria|	EU25 |	1995   |  2500
AT	|Austria|	EU27 |	1995   |  2500
AT	|Austria|	EU28 |	1995   |  2500
BE	|Belgium|	EA	 |  1999   |  2500
BE	|Belgium|	EA12 |  1999   |  2500
BE	|Belgium|	EA13 |  1999   |  2500
BE	|Belgium|	EA16 |  1999   |  2500
... | ...   |   ...  |   ...   |  ...
and stored in a directory named `B`. In order to create/update the SAS table `A`, as described above, in 
library `C`, it is then enough to run:

	%_countryxzone(cds_zonexyear=A, cfg=B, clib=C);

Note that, by default, the command `%%_countryxzone;` runs:

	%_countryxzone(cds_ctryxzone=&G_PING_COUNTRYxZONE, 
				   cfg=&G_PING_AGGREGATES/config, 
				   clib=&G_PING_LIBCFG);

### Example
Generate the table `COUNTRYxZONE` in the `WORK` directory:

	%_countryxzone(clib=WORK);

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%str_isgeo](@ref sas_str_isgeo),
[%_zonexyear](@ref cfg_zonexyear).
*/ /** \cond */

%macro _countryxzone(cds_ctryxzone=, cfg=, clib=);

	%if %macro_isblank(cds_ctryxzone) %then %do;
		%if %symexist(G_PING_COUNTRYxZONE) %then 	%let cds_ctryxzone=&G_PING_COUNTRYxZONE;
		%else										%let cds_ctryxzone=COUNTRYxZONE;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_AGGREGATES) %then 		%let cfg=&G_PING_AGGREGATES/config;
		%else										%let cfg=&G_PING_ROOTPATH/5.7_Aggregates/config;
	%end;

	%local l_TIME l_GEO l_ZONE FMT_CODE;

	%if %symexist(G_PING_FMT_CODE) %then 		%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=csv;
	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;
	%if %symexist(G_PING_LAB_TIME) %then 		%let l_TIME=&G_PING_LAB_TIME;
	%else										%let l_TIME=time;
	%if %symexist(G_PING_LAB_ZONE) %then 		%let l_ZONE=&G_PING_LAB_ZONE;
	%else										%let l_ZONE=zone;

	/* option 1:
	%file_import(&cds_ctryxzone, fmt=&FMT_CODE, _ods_=&cds_ctryxzone, 
				idir=&cfg, olib=&clib, getnames=yes);
	*/

	/*option 2:
	 * the following import has issue with numeric variables (YEAR_OUT is imported as a string)
	PROC IMPORT OUT=&lib..&cds_ctryxzone
	    DATAFILE="&cfg/&cds_ctryxzone..&FMT_CODE"
	    DBMS=&FMT_CODE	
		%if %sysfunc(exist(&lib..&cds_ctryxzone)) %then %do;
			REPLACE
		%end;
		;
		delimiter=',';
	    GETNAMES=YES;
	run;
	*/
	DATA &clib..&cds_ctryxzone;
    LENGTH
        &l_GEO             $ 2
        COUNTRY          $ 15
        &l_ZONE          $ 5
        YEAR_IN            8
        YEAR_OUT           8 ;
    FORMAT
        &l_GEO          	$CHAR2.
        COUNTRY          	$CHAR15.
        &l_ZONE             $CHAR5.
        YEAR_IN          4.
        YEAR_OUT         4. ;
    INFORMAT
        &l_GEO              $CHAR2.
        COUNTRY          	$CHAR15.
        &l_ZONE             $CHAR5.
        YEAR_IN          4.
        YEAR_OUT         4. ;
    INFILE "&cfg/&cds_ctryxzone..&FMT_CODE"
		FIRSTOBS=2
        LRECL=34
        ENCODING="LATIN1"
        TERMSTR=CRLF
        DLM=',' /* !!!wrong: '7F'x is the DEL character*/
        MISSOVER
        DSD ;
    INPUT
        &l_GEO           : $CHAR2.
        COUNTRY          : 	$CHAR15.
        &l_ZONE          : 		$CHAR5.
        YEAR_IN          : 4.
        YEAR_OUT         : 4. ;
	run;

	PROC SORT 
		DATA=&clib..&cds_ctryxzone;
		BY &l_GEO;
	run;

	PROC TRANSPOSE  
		DATA=&clib..&cds_ctryxzone
		OUT=&clib..&cds_ctryxzone(drop=data)  
		NAME=data;
		var YEAR_IN YEAR_OUT;
		id &l_ZONE;
		by &l_GEO; 
	run;

%mend _countryxzone;


%macro _example_countryxzone;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Generate the table &G_PING_COUNTRYxZONE of zone history in WORK library; 
	%_countryxzone(clib=WORK);
	%ds_print(&G_PING_COUNTRYxZONE);

	%work_clean(&G_PING_COUNTRYxZONE);

	%put;
%mend _example_countryxzone;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_countryxzone;
*/

/** \endcond */
