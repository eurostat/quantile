## aggregate_join {#sas_aggregate_join}
Join the countries available for aggregate estimation together with their respective
population.
 
	%aggregate_join(dsn, ctry_tab, year, dsn_o, lib=WORK, flag_unit=, pop_file=);

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `ctry_tab` : name of the table where the list of countries with the year of estimation is
	stored;
* `year` : year of interest;
* `flag_unit` : (_option_) ; default: not set; 
* `pop_file` : (_option_) file storing the population of the different countries (_e.g._, what used 
	to be `CCWGH60`); see `SILCFMT` library;
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `dsn_o` : name of the joined dataset.

### Example
Run macro `%%_example_aggregate_join`.
