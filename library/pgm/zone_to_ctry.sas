/**
## zone_to_ctry {#sas_zone_to_ctry}
Return a list and/or a table composed of countries (geo) belonging to a given geographic area (_e.g._, EU28).

	%zone_to_ctry(zone, time=, _ctryclst_=, _ctrylst_=, ctrydsn=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments
* `zone` : code of the zone, _e.g._, EU28, EA19, etc...;
* `time` : (_option_) selected year; if empty, all the countries that belong or once belonged 
	to the area are returned; default: not set;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
* `_ctryclst_` or `_ctrylst_` : (_option_) name of the macro variable storing the output list, either a list of 
	(comma separated) strings of countries ISO3166-codes in-between quotes when `_ctryclst_` is passed, 
	or an unformatted list when `_ctrylst_` is passed; those two options are incompatible;
* `ctrydsn` : (_option_) name of the output table (stored in `WORK`) where the list of countries found will be 
	stored; this option can be used contemporaneously with either of the options `_ctryclst_` or `_ctrylst_` above.

### Note 
The table in the configuration dataset `cds_ctryxzone` contains in fact for each country in the EU+EFTA 
geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that `zone` needs to be defined as a field in the table `cds_ctryxzone`.

See [%ctry_in_zone](@ref sas_ctry_in_zone) for further description of this table.

### Examples
Let us consider the simple following example:

	%let ctry_glob=;
	%let zone=EU28;
	%let year=2010;
	%zone_to_ctry(&zone, year=&year, _ctryclst_=ctry_glob);
	
returns the (quoted) list of 28 countries: 
`ctry_glob=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK","BG","RO")` 
(since `HR` is missing), while we can change the desired format of the output list (using `_ctrylst_` 
instead of `_ctryclst_`):

	%zone_to_ctry(&zone, &year, _ctrylst_=ctry_glob);

to return `ctry_glob=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO`. 
Let's consider other EU zones in 2015, for instance:

	%let zone=EFTA;
	%let year=2015;
	%zone_to_ctry(&zone, &year, _ctryclst_=ctry_glob);

returns `ctry_glob=("CH","NO","IS","LI")`, while:

	%let zone=EEA18;
	%zone_to_ctry(&zone, &year, _ctrylst_=ctry_glob);

returns `ctry_glob=AT BE DE DK EL ES FI FR IE IS IT LU NL NO PT SE UK LI`. Let us now consider the cases 
where the outputs are stored in tables, _e.g._:

	%zone_to_ctry(EA12, time=2015, ctrydsn=dsn);

will return in the dataset `dsn` (stored in `WORK` directory) the following table:
| zone | geo | year_in | year_out |  
|------|-----|---------|----------|
| EA12 | AT  |  1999   |  2500    |	   
| EA12 | BE  |  1999   |  2500    |     
| EA12 | DE  |  1999   |  2500    |     
| EA12 | ES  |  1999   |  2500    |     
| EA12 | FI  |  1999   |  2500    |     
| EA12 | FR  |  1999   |  2500    |     
| EA12 | IE  |  1999   |  2500    |     
| EA12 | IT  |  1999   |  2500    |     
| EA12 | LU  |  1999   |  2500    |     
| EA12 | NL  |  1999   |  2500    |     
| EA12 | PT  |  1999   |  2500    |     
| EA12 | EL  |  2001   |  2500    |     
while:

	%zone_to_ctry(EU28, ctrydsn=dsn);

will return (note the absence of `time`) in the dataset `dsn` the following table:
| zone | geo | 
|------|-----|
| EU28 |  AT |
| EU28 |  BE | 
| EU28 |  BG |
| EU28 |  CY |
| EU28 |  CZ |
| EU28 |  DE |
| EU28 |  DK |
| EU28 |  EE |
| EU28 |  EL |
| EU28 |  ES |
| EU28 |  FI |
| EU28 |  FR |
| EU28 |  HR |
| EU28 |  HU |
| EU28 |  IE |
| EU28 |  IT |
| EU28 |  LT |
| EU28 |  LU |
| EU28 |  LV |
| EU28 |  MT |
| EU28 |  NL |
| EU28 |  PL |
| EU28 |  PT |
| EU28 |  RO |
| EU28 |  SE |
| EU28 |  SI |
| EU28 |  SK |
| EU28 |  UK |
and finally:

	%zone_to_ctry(EFTA, time=2015, ctrydsn=dsn);

will return (note that `EFTA` is recognised) in the dataset `dsn` the following table:
zone | geo |year_in |year_out|
-----|-----|--------|--------|
EFTA | CH  |  1960  |  2500  |  
EFTA | NO  |  1960  |  2500  |  
EFTA | IS  |  1970  |  2500  |  
EFTA | LI  |  1991  |  2500  |  

Run macro `%%_example_zone_to_ctry` for more examples.

### See also
[%ctry_in_zone](@ref sas_ctry_in_zone), [%ctry_to_zone](@ref sas_ctry_to_zone), [%zone_replace](@ref sas_zone_replace),
[%_countryxzone](@ref cfg_countryxzone);.
*/ /** \cond */

%macro zone_to_ctry(zone				/* Code of a geographical area in the EU 										(REQ) */
					, time=				/* Year of interest																(OPT) */
					, _ctryclst_=		/* Name of the macro variable storing the output formatted list of countries 	(OPT) */
					, _ctrylst_=		/* Ibid, as an unformatted list 												(OPT) */
					, ctrydsn=          /* Name of output dataset storing the list of countries  						(OPT) */
					, cds_ctryxzone=	/* Configuration dataset storing geographical areas								(OPT) */
					, clib=				/* Name of the library storing configuration file								(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_ctrylst_) EQ 1 and %macro_isblank(_ctryclst_) EQ 1 and %macro_isblank(ctrydsn) EQ 1, mac=&_mac,		
			txt=%bquote(!!! One of at least of output parameters _CTRYCLST_, _CTRYLST_ or CTRYDSN needs to be set !!!))
			or
	 		%error_handle(ErrorInputParameter, 
				%macro_isblank(_ctrylst_) EQ 0 and %macro_isblank(_ctryclst_) EQ 0, mac=&_mac,		
				txt=!!! Incompatible parameters _CTRYCLST_ and _CTRYLST_ : one only can be selected !!!) %then 
		%goto exit;

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

	%local TMP 		/* temporary dataset */
		l_GEO 		/* default name of the geo variable */
		ans 		/* temporary variable used for various testing */
		_ctrylst; 	/* output returned list */
	%let TMP=TMP_&_mac;

	/* set the default geo variable */
	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;

	%if not %macro_isblank(ctrydsn) %then 	%do;	 			
		%if %error_handle(ErrorInputParameter, 
				%ds_check(&ctrydsn, lib=WORK) EQ 1, mac=&_mac, 
				txt=! Output dataset %upcase(&ctrydsn) already exists - Will be overwritten !,
				verb=warn) %then 
			%goto warning; /* do nothing, just warn the user */ 
	%end;
	%warning:

	/* test the string passed as a parameter */
	%str_isgeo(&zone, _ans_=ans, cds_ctryxzone=&cds_ctryxzone, clib=&clib);

	%if %error_handle(WarningInputParameter, 
		 	&ans EQ 1, mac=&_mac, 
			txt=%quote(! String %upcase(&zone) is the ISO-code of a country - Returned as is !), 
			verb=warn) %then %do;
		%if not %macro_isblank(_ctryclst_) %then
			%let &_ctryclst_=("&zone");
		%else
			%let &_ctrylst_=&zone;
		%goto exit;
	%end;
	%else %if %error_handle(ErrorInputParameter, 
		 	&ans EQ 0, mac=&_mac, 
			txt=%quote(!!! String %upcase(&zone) not recognised as a geographical area of EU !!!)) %then 
		%goto exit; 
	/* otherwise: at this stage ans=2, i.e. zone is actually a geographical zone: proceed... */

	/* run the table creation */
	PROC SQL noprint;
		CREATE TABLE &TMP AS
		SELECT distinct 
		%if not %macro_isblank(time) and "&time"^="." %then %do;
			min(&zone) as year_in,
			max(&zone) as year_out,
		%end;
		&l_GEO
		FROM &clib..&cds_ctryxzone
		WHERE not missing(&zone)
		%if %macro_isblank(time) %then %do;
			ORDER BY &l_GEO
		%end;
		%else %do;
			GROUP BY &l_GEO
		%end;
		%if not %macro_isblank(time) and "&time"^="." %then %do;
			HAVING (year_out>&time) & (year_in<=&time)
		%end;
		;
	quit;

	%ds_isempty(&TMP, var=&l_GEO, _ans_=ans);
	%if %error_handle(ErrorInputParameter, 
		 	&ans EQ 1, mac=&_mac, 
			txt=!!! Empty geographic zone %upcase(&zone) !!!) %then 
		%goto exit; 

	%if not %macro_isblank(_ctryclst_) %then %do;
		/* we decide to return an unformatted list */
		%var_to_clist(&TMP, &l_GEO, _varclst_=&_ctryclst_); 
	%end;
	%else %if not %macro_isblank(_ctrylst_) %then %do;
		/* we return a formatted list of quoted strings */
		%var_to_list(&TMP, &l_GEO, _varlst_=&_ctrylst_); 
	%end;

	/* other method: through an intermediary variable:
	%if not (%macro_isblank(_ctryclst_) and %macro_isblank(_ctrylst_)) %then %do;
		%var_to_list(&TMP, &l_GEO, _varlst_=_ctrylst); 
		%if not %macro_isblank(_ctrylst_) %then
			%let &_ctrylst_=&_ctrylst;
		%else
			%let &_ctryclst_=(%list_quote(&_ctrylst));
	%end;
	*/

	%if not %macro_isblank(ctrydsn) %then %do;	 		
		DATA WORK.&ctrydsn;
			format zone &l_GEO
				%if not %macro_isblank(time) and "&time"^="." %then %do;
					year_in year_out
				%end;
				;
			SET &TMP;
			zone="&zone";
		run;
	%end;

	/* clean */
	%work_clean(&TMP);

	%exit:
%mend zone_to_ctry;


%macro _example_zone_to_ctry;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ctry octry;
	%let dsn=_TMP%upcase(&sysmacroname);

	/* check http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:EU_enlargements */

	%let year=2015;
	%let zone=USA;
	%put;
	%put (i) Dummy test with zone=&zone ...;
	%zone_to_ctry(&zone, time=&year, _ctrylst_=ctry);
	%if %macro_isblank(&ctry) %then 	%put OK: TEST PASSED - Geographical area not recognised: nothing returned;
	%else 								%put ERROR: TEST FAILED - Geographical area wrongly interpreted: &ctry returned;	

	%let year=2015;
	%let zone=EE;
	%put;
	%put (ii) Dummy test single country zone=&zone ...;
	%zone_to_ctry(&zone, time=&year, _ctryclst_=ctry);
	%if &ctry=("&zone") %then 			%put OK: TEST PASSED - Single country recognised: ("&zone") returned;
	%else 								%put ERROR: TEST FAILED - Single country not recognised: &ctry returned;	

	%let zone=EU28;
	%let year=2010;
	%put;
	%put (iii) Consider zone=&zone and year=&year (HR is not present), and store the output in a table...;
	%zone_to_ctry(&zone, time=&year, _ctrylst_=ctry, ctrydsn=&dsn);
	/* should return actual EU27 (1 January 2007 - 30 June 2013) */
	%let octry=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO;
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	
	%ds_print (&dsn);

	%put;
	%put (iv) Same code, giving up the year ...;
	%zone_to_ctry(&zone, _ctrylst_=ctry);
	/* should return actual EU27 (1 January 2007 - 30 June 2013) */
	%let octry=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO HR;
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2015;
	%put;
	%put (v) Same code and year=&year (should give the same result) ...;
	%zone_to_ctry(&zone, time=&year, _ctrylst_=ctry);
	/* should return actual EU28 (from 1 July 2013) */
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2010;
	%put;
	%put (vi) Same example returning an unformatted list this time ...;
	%zone_to_ctry(&zone, time=&year, _ctryclst_=ctry);
	/* should return actual EU27 (1 January 2007 - 30 June 2013) */
	%let octry=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK","BG","RO");
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2004;
	%put;
	%put (vii) Consider zone=&zone and year=&year ...;
	%zone_to_ctry(&zone, time=&year, _ctryclst_=ctry);
	/* should return actual EU25 (1 May 2004 - 31 December 2006) */
	%let octry=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK");
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=1998;
	%put;
	%put (viii) Same code and year=&year ...;
	%zone_to_ctry(&zone, time=&year, _ctryclst_=ctry);
	/* should return actual EU15 (1 January 1995 - 30 April 2004) */
	%let octry=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE");
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	

	%let year=2010;
	%let zone=EA18;
	%put;
	%put (ix) Consider zone=&zone and year=&year, and store the output in a table ...;
	%zone_to_ctry(&zone, time=&year, _ctrylst_=ctry, ctrydsn=&dsn);
	%let octry=AT BE DE ES FI FR IE IT LU NL PT EL SI CY MT SK;
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	
	%ds_print (&dsn);

	%put;

	%work_clean(&dsn);
%mend _example_zone_to_ctry;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_zone_to_ctry;  
*/

/** \endcond */
