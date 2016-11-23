/** 
## silcx_ind_working {#sas_silcx_ind_working}
Create a working copy of a given indicator, possibly including already calculated values for other 
countries during the same year.

	%silcx_ind_working(idsn, odsn, time=, geo=, ilib=);

### Arguments
* `idsn` : an input dataset reference;
* `time` : (_option_) period (year) of interest; default: empty;
* `geo` : (_option_) unformatted (blank separated) list of country/geographical area of interest; 
	when filled as a geographical area, all countries already present in the table are retrieved; 
	default: empty, and the structure of the input table `idsn` is simply used as a template for `odsn`;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
`odsn` : name of the output dataset (in `WORK` library) where a copy of the original indicator or its
	structure is stored.

### Examples
When dealing with EU-SILC datasets and considering the already existing indicator `LI01` as an input
source dataset, you can run the commands:

	libname rdb "&G_PING_C_RDB";
	%silcx_ind_working(LI01, dsn, ilib=rdb);

so as to create, in `WORK` library, the dataset `dsn` that is initialised with the following table: 
| geo | time | indic_il  | hhtyp       | currency | ivalue       | iflag | unrel | lastup  | lastuser |
|-----|------|-----------|-------------|----------|--------------|-------|-------|---------|----------|
|     |      |           |             |          |              |       |       |         |          |
hence, `dsn` is shaped like `LI01`.

If instead, your run (still using the same indicator as a source table):

	%silcx_ind_working(LI01, dsn, geo=AT BE EU28, time=2015, ilib=rdb);

the dataset `dsn` created in `WORK` library will this time look like this:
geo | time | indic_il  | hhtyp       | currency | ivalue       | iflag | unrel | lastup  | lastuser
----|------|-----------|-------------|----------|--------------|-------|-------|---------|---------
LV	| 2015 | LI_C_MD60 | A1          | NAC      | 3497.0429508 | .     | 0     | 03FEB16 | pillapa
LV	| 2015 | LI_C_MD60 | A1          | EUR      | 3497.0429508 | .     | 0     | 03FEB16 | pillapa
LV	| 2015 | LI_C_MD60 | A1          | PPS      | 4855.0216312 | .     | 0     | 03FEB16 | pillapa
LV	| 2015 | LI_C_MD60 | A2_2CH_LT14 | NAC      | 7343.7901967 | .     | 0     | 03FEB16 | pillapa
... | .....|    ...    |    ...      | ...      |      ...     | ...   | ...   |   ...   |   ...
where observations are taken for `time=2015` and `geo` as any country/zone already present in `LI01` 
at the exception of AT, BE and EU28.

See `%%_example_silcx_ind_working` for more examples.

### Notes
The following rules apply:
	* when none of `geo` and `time` parameters are passed, the structure of the table (_i.e._, its fields)
	are simply reproduced in `odsn`:

	    PROC SQL;
		   CREATE TABLE WORK.&odsn like &ilib..&idsn; 
	    quit; 
	* when `geo` parameter is passed but not `time`, all countries not represented in `geo` are retrieved
	for all years present in the dataset:

	    PROC SQL;
			CREATE TABLE WORK.&odsn  AS
			SELECT * FROM &ilib..&idsn 
			WHERE geo not in %list_quote(&geo);
	    quit; 
	* when `time` parameter is passed but not `geo`, all countries are retrieved for the given 
	year `time`:

        PROC SQL;
		    CREATE TABLE WORK.&odsn  AS
		    SELECT * FROM &ilib..&idsn 
		    WHERE time = &time;
	    quit; 
	* when both parameters `geo` and `time` are passed, all countries not represented in `geo` are retrieved 
	for the given year `time`.

	    PROC SQL;
			CREATE TABLE WORK.&odsn  AS
			SELECT * FROM &ilib..&idsn 
			WHERE geo not in %list_quote(&geo) and time = &time;
	    quit; 

### See also
[%ds_copy](@ref sas_ds_copy).
*/ /** \cond */

%macro silcx_ind_working(idsn	/* Input dataset 										(REQ) */
						, odsn	/* Output dataset 										(REQ) */ 
						, time=	/* Year of interest 									(REQ) */
						, geo=	/* Country/geographical area of interest 				(REQ) */
						, ilib=	/* Name of the output library where odsn will be stored (OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* test the existence of the working dataset */
	%if %error_handle(ExistingDataset, 
			%ds_check(&odsn, lib=WORK) EQ 0, mac=&_mac,
			txt=%quote(! Table already exists in WORKing directory !), verb=warn) %then 
		%work_clean(&odsn); 

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* check if we passed any geographical area:
	* 	- if so, collect all countries data
	* 	- otherwise, just copy the structure of the data */

	/* first check that GEO is actually passed */
	%if %macro_isblank(geo) and %macro_isblank(time) %then
		%goto working_like;  /* proceed... */

	%local ans 	/* temporary answer */
		l_GEO	/* name of the geo variable */
		l_TIME;	/* name of the time variable */

	/* check wether a country or a geographical area was passed as geo */
	%str_isgeo(&geo, _ans_=ans);
	%let ans=%list_find(&ans, 2);
	%if not %macro_isblank(ans) /* look for geographical area */ %then 	
		%goto working_copy;
	/* %else %goto working_like; /* ie., just proceed */

	%working_like:
	/* create the temporary table */
	%ds_copy(&idsn, &odsn, mirror=LIKE, ilib=&ilib, olib=WORK); 
	%goto exit; 

	%working_copy:
	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;
	%if %symexist(G_PING_LAB_TIME) %then 		%let l_TIME=&G_PING_LAB_TIME;
	%else										%let l_TIME=time;
	/* "collect" the already computed values into the temporary table 
	 * note that we collect all data from same year, possibly other countries/zones */
	%local where;
	%if not %macro_isblank(geo) %then 							%let geo=(%list_quote(&geo));
	%if not %macro_isblank(geo) %then 							%let where=%quote(&l_GEO NOT in &geo);
	%if not (%macro_isblank(geo) or %macro_isblank(time)) %then %let where=&where %quote(and);
	%if not %macro_isblank(time) %then							%let where=&where %quote(&l_TIME = &time); 	
	%ds_copy(&idsn, &odsn, mirror=COPY, where=&where, ilib=&ilib, olib=WORK); 
	%goto exit; /* useless, purely cosmetic */

	%exit:
%mend silcx_ind_working;

%macro _example_silcx_ind_working;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn;
	%let dsn=TMP&sysmacroname;
		
	libname rdb "&G_PING_C_RDB";

	%silcx_ind_working(LI01
					, &dsn
					, ilib=rdb
				);

	%silcx_ind_working(LI01
					, &dsn
					, geo=AT EU28
					, time=2015
					, ilib=rdb
				);
	%ds_print(&dsn);
	%work_clean(&dsn);
%mend _example_silcx_ind_working;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silcx_ind_working;
*/

/** \endcond */

