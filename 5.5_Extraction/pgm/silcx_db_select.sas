/** 
## silcx_db_select {#sas_silcx_db_select}
Select and append data from cross-sectional bulk databases (_i.e._, raw H, P, D and R tables) given a period 
and/or a list of countries.

	%silcx_db_select(time, geo=, db=, odsn=, ilib=, olib=, cds_ctryxzone=, clib=);

### Arguments
* `time` : a (list of) selected year(s); default: not set;
* `geo` : (_option_) a (list of) string(s) which represent(s) ISO-codes or geographical zones;
* `db` : (_option_) database(s) to retrieve; it can be any of the character values defined through 
	the global variable `G_PING_BASETYPES` (_i.e._, `D, H, P, R`), so as to represent the 
	corresponding bulk databases (files) to append to the output dataset(s); 
* `ilib` : (_option_) name of the input library where the bulk database is stored; default to the 
	library associated to the full path given by the value `&G_PING_PDB`;
* `olib` : (_option_) name of the output library where the datasets passed through `odsn` (see 
	below) will be stored; default to `WORK`;
* `cds_ctryxzone, clib` : (_options_) configuration file storing the description of geographical 
	areas, and the library where it is stored; for further description of the table, see 
	[%_countryxzone](@ref cfg_countryxzone).
 
### Returns
`odsn` : output reference table(s) created as a concatenation (_i.e._ append operation) ot the bulk datasets
extracted from the databases in `db`; in practice, all bulk datasets (files) with generic name of the form 
`c&yy.&_db` where:
	+ `_db` is any element of `db` (_i.e._, either `D, H, P`, or `R`),
	+ `yy` is composed of the last two digits of any element of `time` (_i.e._, if `time=2014`, then `yy=14`),

are retrieved from the database library `ilib`.

### Examples
Run `%%_example_silcx_db_select` for examples.

### Reference
Carr, D.W. (2008): ["When PROC APPEND may make more sense than the DATA STEP"](http://www2.sas.com/proceedings/forum2008/085-2008.pdf).

### See also
[%silcx_ds_extract](@ref sas_silcx_ds_extract),
[%_countryxzone](@ref cfg_countryxzone).
*/ /** \cond */

%macro silcx_db_select(time				/* Year of interest										(REQ) */
					, geo=				/* (List of) geographical area(s)/country(ies)  		(OPT) */
					, db=				/* Code of generic dataset extracted 					(OPT) */
					, odsn=				/* Name of output datasets 								(OPT) */
					, olib=				/* Name of output library 								(OPT) */
					, ilib=				/* Name of input library where bulk datasets are stored (OPT) */
					, cds_ctryxzone=	/* Configuration dataset storing geographical areas		(OPT) */
					, clib=				/* Name of the library storing configuration file		(OPT) */
					) ;
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(ilib) %then %do;
		%if %symexist(G_PING_LIBPDB) %then 			%let ilib=&G_PING_LIBPDB;
		/*%if %symexist(G_PING_PDB) %then %do;
			libname pdb "&G_PING_PDB"; %let ilib=pdb;
		%end; */
		%else										%let ilib=WORK;
	%end;

	/* set the default file of geographical zones/areas */
	%if %macro_isblank(clib) %then %do; 			
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end; 

	%if %macro_isblank(cds_ctryxzone) %then %do; 			
		%if %symexist(G_PING_COUNTRYxZONE) %then 	%let cds_ctryxzone=&G_PING_COUNTRYxZONE;
		%else										%let cds_ctryxzone=COUNTRYxZONE;
	%end; 

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i _j	/* loop increments */
		VARGEO		/* default generic name of the geo variable in all datasets */
		LABGEO		/* default label of the geo variable */
		_idb		/* scanned input database name */
		_odsn		/* scanned output dataset */
		ntime		/* number of input years/periods */
		BASETYPES 	/* Name of bulk datasets */
		nBASETYPES;	/* number of bulk datasets */

	%if %symexist(G_PING_BASETYPES) %then 			%let BASETYPES=&G_PING_BASETYPES;
	%else											%let BASETYPES=D H P R;
	%let nBASETYPES=%list_length(&BASETYPES); /* very unlikely to change, we know... */

	%if %macro_isblank(db) %then 		%let db=BASETYPES;
	%if %error_handle(ErrorInputParameter, 
			%list_difference(%upcase(&db),%upcase(&BASETYPES)) NE ,	mac=&_mac,
			txt=%bquote(!!! Table(s) %upcase(&db) do(es) not exist !!!)) %then
		%goto exit;

	/* set the default geo variable */
	%if %symexist(G_PING_LAB_GEO) %then 		%let LABGEO=&G_PING_LAB_GEO;
	%else										%let LABGEO=geo;
	%if %symexist(G_PING_VAR_GEO) %then 		%let VARGEO=&G_PING_VAR_GEO;
	%else										%let VARGEO=B020;

	/* check output dataset */
	%if %macro_isblank(olib) %then 		%let olib=WORK;
	%if %error_handle(WarningInputParameter, 
			%macro_isblank(odsn) EQ 1 or %list_length(&odsn) NE %list_length(&db), mac=&_mac,
			txt=%bquote(!!! List(s) DB and ODSN must be of same length - Default naming used for output !!!), 
			verb=warn) %then %do;
		%let odsn = &db;
		%goto warning;
	%end;
	%warning:

	/* in case geo is blank, take all possible countries */
	%if %macro_isblank(geo) %then %do ;
		%var_to_list(&cds_ctryxzone, &LABGEO, _varlst_=geo, distinct=yes, lib=&clib);
	%end;

	/* check whether geo is an aggregation, a list of countries or cannot be recognized... and replace
	* it by a list of countries only */
	%zone_replace(&geo, time=&time, _ctrylst_=geo, cds_ctryxzone=&cds_ctryxzone, clib=&clib);

	/* in case geo is blank, this means that all codes in the list could not be recognized. Stop here. */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(geo) EQ 1, mac=&_mac,
			txt=%bquote(!!! Parameter GEO does not contain any recognizable geographical code !!!)) %then
		%goto exit;

	/* check that the library contains the expected tables */

	%do _i = 1 %to %list_length(&db) ;

		%let _idb = %scan(&db,  &_i) ;
		%let _odsn = %scan(&odsn, &_i) ;

		DATA &olib..&_odsn;
			SET 
			%do _j=1 %to %list_length(&time);
				%let yyyy = %scan(&time, &_j);
				%let yy = %substr(&yyyy, 3, 2);

				%if %error_handle(ErrorInputParameter, 
						%ds_check(c&yy.&_idb, lib=&ilib) NE 0, mac=&_mac,		
						txt=%bquote(!!! Dataset c&yy.&_idb not found in library &ilib !!!)) %then %do;
					%goto exit;
				%end;

				&ilib..c&yy.&_idb 
			%end;
			;
			WHERE &idb.&VARGEO in (%list_quote(&geo));
		run;
	%end;

	%exit:
%mend silcx_db_select;


%macro _example_silcx_db_select;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local silc ds;
	%let ds=TMP&sysmacroname;
	libname silc "&G_PING_PDB";

	%put;
	%put (i): Test selection 2006-2008 on AT ;

	%silcx_db_select(			h
					, time=		2006 2007 2008
					, geo=		AT			
					, odsn=		h_at
					/*, ilib=		silc*/
					); 
	DATA &ds;
		SET h_at;
		if _n_ <= 5;
	run;
	%ds_print(&ds);

	%put;
	%put (ii): Test selection 2008 on euro area ;

	%silcx_db_select(			h
					, time=		2008
					, geo=		EA			
					, odsn=		h_ea
					/*, ilib=		silc*/
					); 
	DATA &ds ;
		SET h_ea;
		if _n_ <= 5;
	run;
	%ds_print(&ds);

	libname silc clear;
	%work_clean(h_ea, h_at, &ds);

	%put;
%mend _example_silcx_db_select;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%silcx_db_select;
*/

/** \endcond */

