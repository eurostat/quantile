## aggregate_weight {#sas_aggregate_weight} 
Construct the weighted indicator as the indicator values over the countries weighted
by their respective populations.
 
	%aggregate_weight(zone, grpdim, tab, pop_part, pop_infl, dsn_o, lib=WORK, flag=, flag_zone=);

### Arguments
* `zone` : code of a geographical area, _e.g._, EU28, EA19, etc..;
* `grpdim` : list of fields to consider in the dataset;
* `tab` : working dataset indicator values and populations (_e.g._, the output of [aggregate_join](aggregate_join);
* `pop_part` : numeric variable storing the (partial) population cumulated over those countries
	that will be used for aggregate estimation;
* `pop_infl` : 'inflation' rate between both the global and partial populations, so that:
		`pop_glob = pop_part * infl`;
* `flag` : (_option_) ; default: not set; 
* `flag_zone` : (_option_) ; default: not set;
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `dsn_o` : name of the dataset with indicator value and weighting respective of the countries'
	populations.

### Example
Run macro `%%_example_aggregate_weight`.
