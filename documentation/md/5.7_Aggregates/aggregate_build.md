## aggregate_build {#sas_aggregate_build}
Build the list of countries/years to take into consideration in order to calculate the 
aggregate value for a given indicator and a given area.
 
	%aggregate_build(dsn, ctry_glob, year, 
					 ctry_tab, _pop_infl_=, _run_agg_=, _pop_part_=,
					 take_all=no, nyear_back=0, lib=, pop_file=, 
					 sampsize=0, max_sampsize=0, thres_presence=, thres_reach=);

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `ctry_glob` : list of (comma-separated, in-between quotes) strings representing the ISO-codes
	of all the countries that belong to a given geographical area;
* `year` : year of interest;
* `take_all` : (_option_) take all possible data from the input dataset, whatever the year 
	considered; when set to yes, all other arguments normally used for building the list of
	countries (see below: sampsize, max_sampsize, thres_presence, thres_reach) are ignored; 
	default to no;
* `nyear_back` : (_option_) look backward in time, _i.e._ consider the nyear_back years prior to the
	considered year; default to 0, _i.e._ only data available for current year shall be considered;
* `sampsize` : (_option_) size of the set of countries from previous year that is sequentially added 
	to the list of available countries so as to reach the desired threshold; default to 0, i.e. 
	all available shall be added at once when available;
* `max_sampsize` : (_option_) maximum number of additional countries from previous to take into
	consideration for the estimation; default to 0;
* `thres_presence` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= pop_thres` ? 
	default to 0.7 (_i.e._ `pop_part` should be at least 70% of `pop_glob`);
* `thres_reach` : (_option_) value (in range [0,1]) of the second threshold considered when complementing
	the list of currently available countries with countries from previous years; default: not set; 
* `pop_file` : (_option_) file storing the population of the different countries (_e.g._, what used to be 
	`CCWGH60`); see `SILCFMT` library;
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `ctry_tab` : name of the output table where the list of countries with the year of estimation is
	stored;
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio pop_glob / pop_part;
* `_run_agg_` : name of the macro variables storing the result of the test whhether some aggregates
	shall be computed or not, _i.e._ the result (`yes/no`) of the test:
		`pop_part / pop_glob >= pop_thres` ?
* `_pop_part_` : name of the macro variable storing the final cumulated population considered for 
	the estimation of the aggregate.

### Note
Visit <http://data.worldbank.org/about/data-overview/methodologies>.

### Example
Run macro `%%_example_aggregate_build`.

### See also
[ctry_define](@ref sas_ctry_define), [ctry_select](@ref sas_ctry_select), [ctry_population](@ref sas_ctry_population), and [population_compare](@ref sas_population_compare).
