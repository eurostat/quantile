## aggregate_flag {#sas_aggregate_flag}
Set the flag of the aggregated indicator depending on the zone/year considered
for the estimation and the number of countries actually used in the estimation.

	%aggregate_flag(zone, ctry_glob, year, ctry_tab, _flag_=);

### Arguments
* `zone` : code of a geographical area, _e.g._, EU28, EA19, etc...;
* `ctry_glob` : list of (comma-separated, quote-enclosed) strings representing the ISO-codes 
	of all the countries that belong to the area represented by zone;
* `year` : year of interest;
* `ctry_tab` : list (similar to `ctry_glob`) of (comma-separated, quote-enclosed) strings 
	representing the ISO-codes of the countries that will be actually used for the estimation
	of the aggregated indicator.

### Returns
* `_flag_` : name of the macro variable used to store the flag of the aggregated indicator (_e.g._,
	`s` for estimated). 

### Note
Two types of checked are performed:	
	- one type based on the actual zone/year combination,
	- another type based on the number of countries used in the estimation (`ctry_tab`).
 
### Examples
Run macro `%%_example_aggregate_flag`.
