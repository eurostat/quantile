/** 
## zone_population {#sas_zone_population}
Compute the total aggregated population of a given geographic area (_e.g._, EU28).

	%zone_population(zone, year, _pop_size_=, cds_popxctry=POPULATIONxCOUNTRY, , cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments
* `zone` : code of the zone, _e.g._, EU28, EA19, etc...;
* `year` : year of interest;
* `cds_popxctry, cds_ctryxzone, clib` : (_option_) names and library of the configuration files storing 
	both the population of different countries and the description of geographical areas; by default, 
	these parameters are set to the values `&G_PING_POPULATIONxCOUNTRY`, `&G_PING_COUNTRYxZONE` and 
	`&G_PING_LIBCFG`' respectively; see [%_populationxcountry](@ref cfg_populationxcountry) and 
	[%_countryxzone](@ref cfg_countryxzone)	for further description of the tables.

### Returns
`_pop_size_` : name of the macro variable storing the output figure, _i.e._ the total (cumulated) 
	population of the given geographic area for the given year.

### Example

	%let popsize=;
	%let year=2010;
	%zone_population(EU28, &year, _pop_size_=popsize);

returns the total (cumulated) population of the EU28 area, that was: `popsize=498.870.000` in 2010.

Run macro `%%_example_zone_population` for more examples.

### Note
The table `ds_pop` contains for each country in the EU+EFTA geographic area the total population
for any year from 2003 on (_e.g._, what used to be `CCWGH60`). 
See [%ctry_population](@ref sas_ctry_population) for further description of the table.

### See also
[%ctry_population](@ref sas_ctry_population), [%zone_to_ctry](@ref sas_zone_to_ctry),
[%_populationxcountry](@ref cfg_populationxcountry), [%_countryxzone](@ref cfg_countryxzone).
*/ /** \cond */
;
%macro zone_population(zone				/* Code of a geographical area in the EU 							(REQ) */
					, year=				/* Year of interest													(OPT) */
					, _pop_size_=		/* Name of the macro variable storing the output population size 	(REQ) */
					, cds_popxctry=		/* Configuration dataset storing population figures					(OPT) */
					, cds_ctryxzone=	/* Configuration dataset storing geographical areas					(OPT) */
					, clib=				/* Name of the library storing configuration files					(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pop_size_) EQ 1, mac=&_mac,		
			txt=!!! Output macro variable _POP_SIZE_ not set !!!) %then
		%goto exit;

	/* note: the check on the existence of ds_pop is done in %ctry_population */

	/* first define the list of countries that belong to the desired area (zone) 
	 * in year (year) */
	%local ctry_list; /* temporary list of countries corresponding to zone */
	%zone_to_ctry(&zone, time=&year, _ctrylst_=ctry_list, cds_ctryxzone=&cds_ctryxzone, clib=&clib);

	/* then retrieve the population for each country and sum up */
	%ctry_population(&ctry_list, &year, _pop_size_=&_pop_size_, cds_popxctry=&cds_popxctry, clib=&clib);
	/* the result will be returned in pop_size */

	%exit:
%mend zone_population;


%macro _example_zone_population;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* Note the figures below may get updated - check in population file */

	%local pop_size;
	%let zone=EU28;
	%put The total population of the &zone area is...;

	%let year=2014;
	%put (i) Compute the total population of the &zone area in &year;
	%zone_population(&zone, &year, _pop_size_=pop_size);
	%if &pop_size=508450000 %then 	%put OK: TEST PASSED - Correct population: returns 508450000;
	%else 							%put ERROR: TEST FAILED - Wrong population: returns &pop_size;

	%let year=2013;
	%put (ii) Compute the total population of the &zone area in &year;
	%zone_population(&zone, &year, _pop_size_=pop_size);
	%if &pop_size=506660000 %then 	%put OK: TEST PASSED - Correct population: returns 506660000;
	%else 							%put ERROR: TEST FAILED - Wrong population: returns &pop_size;

	%let zone=EU15;
	%let year=2003;
	%put (iii) Compute the total population of the &zone area in &year;
	%zone_population(&zone, &year, _pop_size_=pop_size);
	%if &pop_size=381070000 %then 	%put OK: TEST PASSED - Correct population: returns 381070000;
	%else 							%put ERROR: TEST FAILED - Wrong population: returns &pop_size;

%mend _example_zone_population;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_zone_population;  
*/

/** \endcond */
