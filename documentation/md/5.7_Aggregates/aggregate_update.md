## aggregate_update {#sas_aggregate_update}
Update the time/zone fields of a given dataset with the content of another dataset.

	%aggregate_update(dsn, zone, year, dsn_o, lib=WORK);

### Arguments
* `dsn` : input dataset to merge into the output dataset;
* `zone, year` : geographical areas (_e.g._ EU28) and year considered respectively; data for
 	`geo=zone` and `time=year` in the input dataset `dsn` (see above) will be merged/stored 
	into the output dataset `dsn_o` (see below);
* `lib` : (_option_) name of the output library; by default: ' ', _i.e._ `WORK` is used.

### Returns
* `dsn_o` : name of the dataset where data are stored/merged; if it does not exist, it is
	created.

### Note
The program is nothing else than:

	%dszone_update(&dsn, &dsn_o, geo_list=&zone, time_list=&year, lib=&lib);

### Example
Run macro `%%_example_aggregate_update`.

### See also
This macro is nothing else than a call to the macro program [dszone_update](@ref sas_dszone_update) (see note).
