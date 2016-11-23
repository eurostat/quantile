## ctry_population {#sas_ctry_population}
Compute the cumulated population of a list of countries.

	%ctry_population(ctry_list, year, _pop_size_=, cds_popxctry=POPULATIONxCOUNTRY, clib=LIBCFG);

### Arguments
* `ctry_list` : list of desired countries defined by their ISO codes (_e.g._, list of MS in EU28);
* `year` : year of interest; 
* `cds_popxctry` : (_option_) configuration file storing the population of different countries; by default,
	it is named after the value `&G_PING_POPULATIONxCOUNTRY` (_e.g._, `POPULATIONxCOUNTRY`); for further 
	description, see [%_populationxcountry](@ref cfg_populationxcountry);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
`_pop_size_` : name of the macro variable storing the output figure, _i.e._ the total (cumulated) 
	population of the given list of countries for the given year.

### Note
The table in the configuration dataset `cds_popxctry` contains in fact for each country in the EU+EFTA 
geographic area the total population for any year from 2003 on (_e.g._, what used to be `CCWGH60`). 
Considering the way `cds_popxctry` is structured, the variable `Y&year` needs to exist in the table.

### Examples

	%let popsize=;
	%let ctry_list=("BE","BG");
	%let year=2007;
	%ctry_population(&ctry_list, &year, _pop_size_=popsize);

returns (with the table defined as above): `popsize=18157207` (sum of values `10584534+7572673` above).

Run macro `%%_example_ctry_population` for more examples.

### See also
[%zone_population](@ref sas_zone_population), [%_populationxcountry](@ref cfg_populationxcountry).
