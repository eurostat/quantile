## calc_aggregate {#sas_calc_aggregate}
Calculate an aggregated indicator over a given geographical area for a given period.

	%calc_aggregate(dsn, zone, year, odsn, grpdim=(), ctry_glob=(), flag=, 
					pop_file=' ', take_all=no, nyear_back=0, sampsize=0, max_sampsize=0, 
					thres_presence=' ', thres_reach=' ', lib=' ');

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `zone` : code of a geographical area, _e.g._, EU28, EA19, etc..
* `year` : year of interest;
* `grpdim` : (_option_) list of fields to consider in the dataset;
* `ctry_glob` : list of (comma-separated, in-between quotes) strings representing the ISO-codes
	of all the countries that belong to a given geographical area;
* `flag` : ;
* `pop_file` : (_option_) file storing the population of the different countries (e.g., what used 
	to be `CCWGH60`); see `SILCFMT` library;
* `take_all, nyear_back, sampsize, max_sampsize` : (_option_) see arguments of macro 
	[zone_build](@ref sas_zone_build);
* `thres_presence, thres_reach` : (_option_) ibid, see arguments of macro [`%zone_build`](@ref sas_zone_build);
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
- `odsn` : output dataset storing the aggregated indicator.

### Examples
Run macro `%%_example_calc_aggregate`.

### See also
The macro program uses aggregate macros: [aggregate_build](@ref sas_aggregate_build), [aggregate_unit](@ref sas_aggregate_unit), 
[aggregate_flag](@ref sas_aggregate_flag), [aggregate_join](@ref sas_aggregate_join), [aggregate_weight](@ref sas_aggregate_weight) 
and [aggregate_update](@ref sas_aggregate_update).

