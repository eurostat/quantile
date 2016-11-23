## ctry_select {#sas_ctry_select}
Return a table storing the list of countries available in a given dataset and for a given
year, or a subsample of it. 

	%ctry_select(idsn, ctry_list, year, odsn, 
				 sampsize=0, force_overwrite=no, ilib=, olib=);

### Arguments
* `idsn` : input reference dataset;
* `ctry_list` : list of (comma-separated) strings of countries ISO-codes represented 
	in-between quotes (_.e.g._, produced as the output of `%zone_to_ctry`);
* `year` : year to consider for the selection of country;
* `sampsize` : (_option_) when >0, only a (randomly chosen) subsample of the countries 
	available in `idsn` is stored in the output table `odsn` (see below); default: 0, 
	_i.e._ no sampling is performed; see also the macro [%ds_sample](@ref sas_ds_sample);
* `force_overwrite` : (_option_) boolean argument set to yes when the table `odsn` is
	to be overwritten; default to `no`, _i.e._ the new selection is appended to the table
	if it already exists;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.
 
### Returns
`odsn` : name of the output table where the list of countries is stored.

### Example
Run macro `%%_example_ctry_select` for examples.

### See also
[%ds_sample](@ref sas_ds_sample).
