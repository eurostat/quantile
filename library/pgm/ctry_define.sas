/* OBSOLETE */
/** \cond
## OBSOLETE ctry_define OBSOLETE {#sas_ctry_define}
Define the list of countries (_i.e._, the ISO codes) included in a given geographic area 
(_e.g._, EU28).

	%ctry_define(zone, year, _ctrylst_=, _ctryclst_=, cds_ctryxzone=, clib=);

### Note
*OBSOLETE - use [%zone_to_ctry](@ref sas_zone_to_ctry) instead - OBSOLETE*

### Arguments
* `zone` : code of a geographical zone, _e.g._, EU28, EA19, etc...;
* `year` : (_option_) year to consider; if empty, all the countries that belong, or once belonged, 
	to the given area `zone` are returned (see [%zone_to_ctry](@ref sas_zone_to_ctry)); by default,
	it is set to the value `&G_PING_VAR_GEO` (_e.g._, `GEO`); 
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for more details, see
	also [%ctry_in_zone](@ref sas_ctry_in_zone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
`_ctryclst_` or `_ctrylst_` : name of the macro variable storing the output list, either a list of 
(comma separated) strings of countries ISO3166-codes in-between quotes when `_ctryclst_` is passed, 
or an unformatted list when `_ctrylst_` is passed; those two options are incompatible.

### Examples
Let us consider a simple example:

	%let ctry_glob=;
	%let zone=EU28;
	%let year=2010;
	%ctry_define(&zone, year=&year, _ctryclst_=ctry_glob);
	
returns the (quoted) list of 28 countries: 
`ctry_glob=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK","BG","RO")` 
(since `HR` is missing), while we can change the desired format of the output list (using `_ctrylst_` 
instead of `_ctryclst_`):

	%ctry_define(&zone, &year, _ctrylst_=ctry_glob);

to return `ctry_glob=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO`. 
Let's consider other EU zones in 2015, for instance:

	%let zone=EFTA;
	%let year=2015;
	%ctry_define(&zone, &year, _ctryclst_=ctry_glob);

returns `ctry_glob=("CH","NO","IS","LI")`, while:

	%let zone=EEA18;
	%ctry_define(&zone, &year, _ctrylst_=ctry_glob);

returns `ctry_glob=AT BE DE DK EL ES FI FR IE IS IT LU NL NO PT SE UK LI`.

Run macro `%%_example_ctry_define`.

### See also
[%str_isgeo](@ref sas_str_isgeo), [%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_in_zone](@ref sas_ctry_in_zone), 
[%var_to_clist](@ref sas_var_to_clist).
*/ 

%macro ctry_define(zone				/* Code of a geographical area in the EU 							(REQ) */
				, year=				/* Considered year 													(OPT) */
				, _ctrylst_=		/* Name of the macro variable storing the output unformatted list 	(OPT) */
				, _ctryclst_=		/* Name of the macro variable storing the output formatted list 	(OPT) */
				, cds_ctryxzone=	/* Configuration dataset storing geographical areas					(OPT) */
				, clib=				/* Name of the library storing configuration file					(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_ctrylst_) EQ 1 and %macro_isblank(_ctryclst_) EQ 1, mac=&_mac,		
			txt=!!! One of at least of output parameters _CTRYCLST_ or _CTRYLST_ needs to be set !!!)
			or
	 		%error_handle(ErrorInputParameter, 
				%macro_isblank(_ctrylst_) EQ 0 and %macro_isblank(_ctryclst_) EQ 0, mac=&_mac,		
				txt=!!! Incompatible parameters _CTRYCLST_ and _CTRYLST_ : one only must be selected !!!) %then 
		%goto exit;

	/* define temporary file */
	%local TMP 		/* temporary dataset */
		ans 		/* temporary variable used for various testing */
		var; 	/* default name of the geo variable */
	%let TMP=TMP_%upcase(&sysmacroname);

	/* arbitrary number: must be> max number of countries in largest EU area	
	%let DEF_NUM_MAX_CTRY_ZONE=50; */

	%if %macro_isblank(clib) %then %do; 			
		%if %symexist(G_PING_LIBCFG) %then 				%let clib=&G_PING_LIBCFG;
		%else											%let clib=SILCFMT;
	%end; 

	%if %macro_isblank(cds_ctryxzone) %then %do; 			
		%if %symexist(G_PING_COUNTRYxZONE) %then 	%let cds_ctryxzone=&G_PING_COUNTRYxZONE;
		%else										%let cds_ctryxzone=COUNTRYxZONE;
	%end; 

	%if %symexist(G_PING_VAR_GEO) %then 			%let var=&G_PING_VAR_GEO;
	%else											%let var=GEO;

	/* test the string passed as a parameter */
	%str_isgeo(&zone, _ans_=ans, cds_ctryxzone=&cds_ctryxzone, clib=&clib);

	%if %error_handle(WarningInputParameter, 
		 	&ans EQ 1, mac=&_mac, 
			txt=%quote(! String %upcase(&zone) is the ISO-code of a country - Returned as is !), verb=warn) %then %do;
		%if not %macro_isblank(_ctryclst_) %then
			%let &_ctryclst_=("&zone");
		%else /* %if not %macro_isblank(_ctrylst_) */ 
			%let &_ctrylst_=&zone;
		%goto exit;
	%end;
	%else %if %error_handle(ErrorInputParameter, 
		 	&ans EQ 0, mac=&_mac, 
			txt=%quote(!!! String %upcase(&zone) not recognised as a geographical area of EU !!!)) %then 
		%goto exit; 
	/* otherwise: at this stage ans=2, i.e. zone is actually a geographical zone: proceed... */
	
	/*
	%if %error_handle(WarningInputParameter, 
		 	%macro_isblank(year) EQ 1, mac=&_mac, 
			txt=%quote(! Year not passed - Current will be used !), verb=warn) %then 
		%let year=%datetime_current(stamp=year);
	*/

	/* retrieve the list of countries included in the zone... */
	%zone_to_ctry(&zone, var=&var, time=&year, ctrydsn=&TMP, cds_ctryxzone=&cds_ctryxzone, clib=&clib);

	%ds_isempty(&TMP, &var, _ans_=ans);
	%if %error_handle(ErrorInputParameter, 
		 	&ans EQ 1, 
			txt=!!! Geographic zone %upcase(&zone) not defined !!!, mac=&_mac) %then 
		%goto exit; 

	%if not %macro_isblank(_ctryclst_) %then %do;
		/* we return a formatted list of quoted strings */
		%var_to_clist(&TMP, &var, _varclst_=&_ctryclst_);
	%end;
	%else /* %if not %macro_isblank(_ctrylst_) */ %do;	
		/* we decide to return an unformatted list */
		%var_to_list(&TMP, &var, _varlst_=&_ctrylst_); 
	%end;

	/* clean */
	%work_clean(&TMP);

	%exit:
%mend ctry_define; 

%macro _example_ctry_define;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ctry octry;
	
	/* check http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:EU_enlargements */

	%let year=2015;
	%let zone=USA;
	%put;
	%put (i) Dummy test with zone=&zone ...;
	%ctry_define(&zone, year=&year, _ctrylst_=ctry);
	%if %macro_isblank(&ctry) %then 	%put OK: TEST PASSED - Geographical area not recognised: nothing returned;
	%else 								%put ERROR: TEST FAILED - Geographical area wrongly interpreted: &ctry returned;	

	%let year=2014;
	%let zone=EE;
	%put;
	%put (ii) Dummy test single country zone=&zone ...;
	%ctry_define(&zone, year=&year, _ctryclst_=ctry);
	%if &ctry=("&zone") %then 			%put OK: TEST PASSED - Single country recognised: ("&zone") returned;
	%else 								%put ERROR: TEST FAILED - Single country not recognised: &ctry returned;	

	%let zone=EU28;
	%let year=2010;
	%put;
	%put (iii) Consider zone=&zone and year=&year (HR is not present)...;
	%ctry_define(&zone, year=&year, _ctrylst_=ctry);
	/* should return actual EU27 (1 January 2007 - 30 June 2013) */
	%let octry=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO;
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%put;
	%put (iv) Same code, giving up the year ...;
	%ctry_define(&zone, _ctrylst_=ctry);
	/* should return actual EU27 (1 January 2007 - 30 June 2013) */
	%let octry=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO HR;
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2015;
	%put;
	%put (v) Same code and year=&year (should give the same result) ...;
	%ctry_define(&zone, year=&year, _ctrylst_=ctry);
	/* should return actual EU28 (from 1 July 2013) */
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2010;
	%put;
	%put (vi) Same example returning an unformatted list this time ...;
	%ctry_define(&zone, year=&year, _ctryclst_=ctry);
	/* should return actual EU27 (1 January 2007 - 30 June 2013) */
	%let octry=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK","BG","RO");
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2004;
	%put;
	%put (vii) Consider zone=&zone and year=&year ...;
	%ctry_define(&zone, year=&year, _ctryclst_=ctry);
	/* should return actual EU25 (1 May 2004 - 31 December 2006) */
	%let octry=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK");
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=1998;
	%put;
	%put (viii) Same code and year=&year ...;
	%ctry_define(&zone, year=&year, _ctryclst_=ctry);
	/* should return actual EU15 (1 January 1995 - 30 April 2004) */
	%let octry=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE");
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2010;
	%let zone=EA18;
	%put;
	%put (ix) Consider zone=&zone and year=&year ...;
	%ctry_define(&zone, year=&year, _ctrylst_=ctry);
	%let octry=AT BE DE ES FI FR IE IT LU NL PT EL SI CY MT SK;
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%put;
%mend _example_ctry_define;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_define;  
*/

/** \endcond */
