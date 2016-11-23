/**
## zone_replace {#sas_zone_replace}
Return a list composed of countries only (geo) belonging to a given geographic area (_e.g._, EU28).

	%zone_replace(geo, time=, _ctrylst_=, _ctryclst_=, , cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments
* `geo` : a list of string(s) which shall represent(s) ISO-codes or geographical zones;
* `time` : (_option_) selected year; if empty, all the countries that belong or once belonged 
	to the area are returned; default: not set;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by 
	default, it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further 
	description, see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the 
	value `&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
`_ctrylst_` or `_ctryclst_` : (_option_) name of the macro variable storing the output list, where 
	all geographical areas present in `geo` have been replaced by the corresponding list of countries; 
	it is encoded , either a list of (comma separated) strings of countries ISO3166-codes in-between 	
	quotes when `_ctryclst_` is passed, or an unformatted list when `_ctrylst_` is passed; those two 
	options are incompatible.

### Note 
The table in the configuration dataset `cds_ctryxzone` contains in fact for each country in the 
EU+EFTA geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that `zone` needs to be defined as a field in the table `cds_ctryxzone`.

### Examples
Let us consider the simple following example:

	%let ctry_glob=;
	%zone_replace(FR EFTA IT, time=2015, _ctryclst_=ctry_glob);

returns the (quoted) list `ctry_glob=("FR","CH","NO","IS","LI","IT")`. 

Run macro `%%_example_zone_replace` for more examples.

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), 
[%ctry_in_zone](@ref sas_ctry_in_zone), [%_countryxzone](@ref cfg_countryxzone).
*/ /** \cond */

%macro zone_replace(__geo			/* (List of) string(s) to be checked as a geographical area/country (REQ) */
					, time=			/* Year of interest													(OPT) */
					, _ctryclst_=		/* Name of the macro variable storing the output list of countries 	(OPT) */
					, _ctrylst_=		/* Ibid, as an unformatted list 									(OPT) */
					, cds_ctryxzone=/* Configuration dataset storing geographical areas					(OPT) */
					, clib=			/* Name of the library storing configuration file					(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

 	%local _i 		/* loop increment */
		_lctries 		/* output answer to the test */
		_geo		/* scanned geographical zone from __geo */
		_ctries;		/* list extracted from __geo of countries only */

	/* loop over the list of zones to check their type */
	%do _i = 1 %to %list_length(&__geo) ;

		%let _geo=%scan(&__geo, &_i); /* use also list_index */

		/* run the zone_to_ctry macro; it returns an empty list if the zone is not recognised */
		%let _lctries=;
		%zone_to_ctry(&_geo, time=&time, _ctrylst_=_lctries, cds_ctryxzone=&cds_ctryxzone, clib=&clib);

		%if %macro_isblank(_lctries) %then /* NOTHING known */
			%goto next;

		%let _ctries=%list_unique(%list_append(&_ctries, &_lctries));

		%next: 
	%end;

	%if %error_handle(WrongInputParameter, 
			%macro_isblank(_ctries) EQ 1, mac=&_mac,
			txt=%bquote(!!! No geographical area/countries identified in input list !!!)) %then
		%goto exit;

	%if not %macro_isblank(_ctryclst_) %then %do;
		/* we return a formatted list of quoted strings */
		%let &_ctryclst_=(%list_quote(&_ctries));
	%end;
	%else /* %if not %macro_isblank(_ctrylst_) */ %do;	
		/* we decide to return an unformatted list */
		data _null_;
			call symput("&_ctrylst_","&_ctries");
		run;
	%end;

	%exit:
%mend zone_replace;


%macro _example_zone_replace;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ctry octry;
	%let dsn=_TMP%upcase(&sysmacroname);

	/* check http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:EU_enlargements */

	%let year=2015;
	%let zone=FR DUMMY EFTA IT;
	%put;
	%put (i) Simple test with zone=&zone ...;
	%zone_replace(&zone, time=&year, _ctryclst_=ctry);
	%let octry=("FR","CH","NO","IS","LI","IT");
	%if &ctry=&octry %then 			%put OK: TEST PASSED - Countries recognised: &octry returned;
	%else 								%put ERROR: TEST FAILED - Countries not recognised: &ctry returned;	

	%let zone=ES DK PL EU28;
	%let year=2010;
	%put;
	%put (ii) Consider zone=&zone and year=&year (HR is not present), and store the output in a table...;
	%zone_replace(&zone, time=&year, _ctrylst_=ctry);
	/* should return actual EU27 (1 January 2007 - 30 June 2013) */
	%let octry=ES DK PL BE DE FR IT LU NL IE UK EL PT AT FI SE CY CZ EE HU LT LV MT SI SK BG RO;
	%if &ctry=&octry %then 	%put OK: TEST PASSED - Correct list of countries returned: &octry;
	%else 					%put ERROR: TEST FAILED - Wrong list of countries returned: &ctry;	
	
%mend _example_zone_replace;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_zone_replace;  
*/

/** \endcond */
