/**
## str_isgeo {#sas_str_isgeo}
Define if a (list of) string(s) can be the ISO-code of a country (_e.g._, BE, AT, BG,...) or a 
geographic area (_e.g._, EU28, EA19, ...), and update this list with geographic areas/countries only.

	%str_isgeo(geo, _ans_=, _geo_=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG, sep=%quote( ));

### Arguments
* `geo` : a list of string(s) which shall represent(s) and ISO-code or a geographical zone;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set;
* `sep` : (_option_) character/string separator in input `geo` list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.

### Returns
* `_ans_` : (_option_) name of the macro variable storing the list of same length as `geo` where the i-th item
	provides the answer of the test above for the i-th item in `geo`, _i.e._:
		+ `1` if it is the ISO-code of a country (_e.g._, `geo=DE`, `geo=CH`, `geo=TR`, ...),
		+ `2` if it is the code/acronym of a geographic area  (_e.g._, `geo=EU28`, or `geo=EFTA`,..),
		+ `0` otherwise;
	either this option or the next one (`_geo_`) must be set so as to run the macro;
* `_geo_` : (_option_) name of the macro variable storing the updated list from which all non-geographical areas 
	or countries have been removed; `_geo_` stores, in this order, first countries, then geographical zones. 

### Examples
Let us consider the following simple example: 

	%let ans=;
	%let geo=;
	%str_isgeo(AT BE DUMMY EU28 FR EA19, _ans_=ans, _geo_=geo);

which returns `ans=1 1 0 2 1 2` and `geo=AT BE FR EU28 EA19`.

Run macro `%%_example_str_isgeo` for more examples.

### Note 
Testing all at once if a list `geo` of strings are actual geographic codes (instead of testing it 
separately for each item of the list) avoids the burden of multiple IO operations on the input 
`cds_ctryxzone` configuration dataset.

### References
1. Official Journal of the European Union, no. [L 328, 28.11.2012](http://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=OJ:L:2012:328:FULL&from=EN).
2. Eurostat _Statistics Explained_ [webpage](http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:Protocol_order) 
on protocol order and country code.

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%ctry_in_zone](@ref sas_ctry_in_zone),
[%_countryxzone](@ref cfg_countryxzone).
*/ /** \cond */

%macro str_isgeo(ctryORzone			/* (List of) string(s) to be checked as a geographical area  		(REQ) */
				, _ans_=			/* Name of the macro variable storing the output of the test 		(REQ) */
				, _geo_=			/* Updated list of geographical areas/countries actually recognised (OPT) */
				, cds_ctryxzone=	/* Configuration dataset storing geographical areas					(OPT) */
				, clib=				/* Name of the library storing configuration file					(OPT) */
				, sep=				/* String separator 												(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* basic logical checks */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(ctryORzone) EQ 1, mac=&_mac,		
			txt=!!! Input variable GEO not passed !!!)
		or
		%error_handle(ErrorInputParameter, 
			%macro_isblank(_ans_) EQ 1 and %macro_isblank(_geo_) EQ 1, mac=&_mac,		
			txt=!!! One of the output macro variables _ANS_ or _GEO_ needs to be set !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i 		/* loop increment */
		__ans 		/* output answer to the test */
		_ctryORzone /* both scanned ctryORzone zone from input list and final ordered output */
		zonelist 	/* list of accepted geographical areas */
		__zones		/* list extracted from ctryORzone somposed of zones only */
		ctrylist	/* list of countries that are members that belong to any of the geographical area */
		__ctries	/* list extracted from ctryORzone composed of countries only */
		l_GEO;		/* default name of the ctryORzone variable */
	/* initialise the test output */	
	%let __ans=;
	/* the operation consists in:
	* - checking that all passed parameters are indeed zones or countries;
    * - ordering the list by : countries, then zones */ 
	%let __zones=;
	%let __ctries=;

	%if %macro_isblank(sep) %then 	%let sep=%quote( );  /* list separator */

	/* set the default file of geographical zones/areas */
	%if %macro_isblank(clib) %then %do; 			
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end; 

	%if %macro_isblank(cds_ctryxzone) %then %do; 			
		%if %symexist(G_PING_COUNTRYxZONE) %then 	%let cds_ctryxzone=&G_PING_COUNTRYxZONE;
		%else										%let cds_ctryxzone=COUNTRYxZONE;
	%end; 

	/* make some existence checks */
	%if %error_handle(ErrorInputParameter, 
			%ds_check(&cds_ctryxzone, lib=&clib) EQ 1, mac=&_mac, 
			txt=!!! File %upcase(&cds_ctryxzone) does not exist !!!) %then 
		%goto exit; 

	/*	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else											%let l_GEO=geo;
	* this is retrieved from the table in fact: list "l_GEO=%list_slice" below */

	/* retrieve the list of zones from the list of variables in cds_ctryxzone */
	%ds_contents(&cds_ctryxzone, _varlst_=zonelist, varnum=yes, lib=&clib);
	/* get rid of the first variable: &l_GEO */
	%let l_GEO=%list_slice(&zonelist, ibeg=1, iend=1); /* retrieve it directly */
	%let zonelist=%list_slice(&zonelist, ibeg=2);

	/* retrieve the list of countries from the list of CTRYORZONE observations in cds_ctryxzone */
	%let ctrylist=;
	%var_to_list(&cds_ctryxzone, &l_GEO, _varlst_=ctrylist, lib=&clib, distinct=yes);

	/* test whether the tested parameter actually appears in one of the lists above */	
	%do _i=1 %to %list_length(&ctryORzone);
		%let _ctryORzone = %scan(&ctryORzone, &_i, &sep);
		%if %list_count(&ctrylist, &_ctryORzone)  %then %do;
			%let __ans=&__ans 1;
			/* append the country found to the list of countries */
			%if %macro_isblank(__ctries) %then	%let __ctries=&_ctryORzone;
			%else 								%let __ctries=&__ctries.&sep.&_ctryORzone; 
		%end;
		%else %if %list_count(&zonelist, &_ctryORzone)  %then %do; 
			%let __ans=&__ans 2;
			/* append the zone found to the list of zones */
			%if %macro_isblank(__zones) %then	%let __zones=&_ctryORzone;
			%else 								%let __zones=&__zones.&sep.&_ctryORzone; 
		%end;
		%else %do; 
			%let __ans=&__ans 0;
		%end;
	%end;

	/* store the result */
	data _null_;
		%if %macro_isblank(_ans_) EQ 0 %then %do; 	
			call symput("&_ans_","&__ans");
		%end; 
		/*
		%if not %macro_isblank(_ctrylst_) %then %do; 
			call symput("&_ctrylst_","&__ctries");
		%end;
		%if not %macro_isblank(_zonelst_) %then %do; 
			call symput("&_zonelst_","&__zones");
		%end;
		*/
		%if %macro_isblank(_geo_) EQ 0 %then %do; 
			%let _ctryORzone=%list_append(&__ctries, &__zones, sep=&sep);
			call symput("&_geo_", "&_ctryORzone");
		%end; 
	run;

	%exit:
%mend str_isgeo;


%macro _example_str_isgeo; 
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ans var geo ogeo oans;

	%let var=DUMMY;
	%put;
	%put (i) Test whether &var is a country code or an area acronym;
	%str_isgeo(&var, _ans_=ans);
	%put ans=&ans;
	%if &ans=0 %then 	%put OK: TEST PASSED - DUMMY code: 0 returned;
	%else 				%put ERROR: TEST FAILED - DUMMY code: &ans returned;

	%let var=IT;
	%put;
	%put (ii) Test whether &var is a country code or an area acronym;
	%str_isgeo(&var, _ans_=ans);
	%if &ans=1 %then 	%put OK: TEST PASSED - Country ISO code: 1 returned;
	%else 				%put ERROR: TEST FAILED - Country ISO code: &ans returned;

	%let var=EA19;
	%put;
	%put (iii) Test whether &var is a country code or an area acronym;
	%str_isgeo(&var, _ans_=ans);
	%if &ans=2 %then 	%put OK: TEST PASSED - Geographic zone: 2 returned;
	%else 				%put ERROR: TEST FAILED - Geographic zone: &ans returned;

	%let var=DUMMY EA19 IT;
	%put;
	%put (iv) Test all together which strings of the list &var are country codes and area acronyms;
	%let oans=0 2 1;
	%let ogeo=IT EA19;
	%str_isgeo(&var, _ans_=ans, _geo_=geo);
	%if &ans=&oans and &geo=&ogeo %then 
		%put OK: TEST PASSED - Correct result: &oans returned, and updated list: &ogeo;
	%else 									
		%put ERROR: TEST FAILED - Wrong result: &ans, and wrong list: &geo returned;

	%let var=AT BE DUMMY EU28 FR EA19;
	%put;
	%put (v) Test whether &var is a country code or an area acronym;
	%let oans=1 1 0 2 1 2;
	%let ogeo=AT BE FR EU28 EA19;
	%str_isgeo(&var, _ans_=ans, _geo_=geo);
	%if &ans=&oans and &geo=&ogeo %then 	
		%put OK: TEST PASSED - Geographic zone: &oans returned, and updated lists: &ogeo;
	%else 									
		%put ERROR: TEST FAILED - Wrong geographic zone: &ans, and wrong list: &geo returned;

	%put;
%mend _example_str_isgeo;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_str_isgeo; 
*/

/** \endcond */
