## str_dsname {#sas_str_dsname}
Find the first unused dataset (named with a generic name), adding a prefix and a numeric suffix 
as large as necessary to make it unique.

	%let name=%str_dsname(name, prefix=_, lib=WORK);
  
### Arguments
* `name` : string to be used as a core name for the dataset;
* `prefix` : (_option_) leading string/character to be used; default: `prefix=_`;
* `lib` : (_option_) name of the library where the desired dataset shall be found; by default: 
	empty, _i.e._ `WORK` is used.

### Returns
`name` : unique name of the desired dataset. 

### Examples
Consider the situation where some dataset `_dsn`, `_dsn1` and `_dsn2` already exist in the `WORK`ing 
library, then:

	%let name=%str_dsname(dsn, prefix=_);

returns `name=_dsn3`.

Run macro `%%_example_str_dsname` for examples.

### Note
This macro is derived from the [`%%MultiTransposeNewDatasetName` macro](http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html) 
of L. Joseph.

### See also
[%ds_check](@ref sas_ds_check), [%ds_create](@ref sas_ds_create), [%str_dslist](@ref sas_str_dslist),
[EXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210903.htm),
[%MultiTranspose][http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html].
