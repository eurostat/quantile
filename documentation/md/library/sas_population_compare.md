## population_compare {#sas_population_compare}
Compare the ratio of two populations with a given threshold.

	%population_compare(pop_glob, pop_part, _pop_infl_=, _run_agg_=, pop_thres=0.7);

### Arguments
* `pop_glob, pop_part` : two (string/numeric) variables storing respectively the global and partial
	population figures to compare, where `pop_glob > pop_part`;
* `pop_thres` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= pop_thres` ?
	default to 0.7 (_i.e._ `pop_part` should be at least 70% of `pop_glob`).
 
### Returns
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio `pop_glob / pop_part`;
* `_run_agg_` : name of the macro variables storing the result of the test whhether some aggregates
	shall be computed or not, _i.e._ the result (yes/no) of the test:
		`pop_part / pop_glob >= pop_thres` ?

### Examples
_Alleluia!!!_
	
	%let pop_infl=;
	%let run_agg=;
	%population_compare(1, 0.1, _pop_infl_=pop_infl, _run_agg_=run_agg, pop_thres=0.2);

returns `pop_infl=10` and `run_agg=no`.

	%population_compare(1, 0.2, _pop_infl_=pop_infl, _run_agg_=run_agg, pop_thres=0.2);

returns `pop_infl=5` and `run_agg=yes` (note that we indeed test `>=`).

	%population_compare(1, 0.5, _pop_infl_=pop_infl, _run_agg_=run_agg, pop_thres=0.2);

returns `pop_infl=2` and `run_agg=yes`.

Run macro `%%_example_population_compare` for more examples.

### See also
[%ctry_population_compare](@ref sas_ctry_population_compare)
