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
