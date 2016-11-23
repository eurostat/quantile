## var_compare {#sas_var_compare}
Compare variables of a given dataset.

	%var_compare(dsn, var, varc=, cdsn=, _ans_=, 
				typ=yes, len=no, fmt=no, vfmt=no, infmt=no, pos=no, lab=no, 
				lib=WORK, libc=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : a variable name whose properties are considered for comparison;
* `varc` : (_option_) a second variable to compare to the first one;
* `dsnc` : (_option_) a second dataset reference;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.
* `libc` : 
`typ, lab, fmt, infmt, len, pos` : boolean flags (`yes/no`) set to define which attributes/properties 
	of the variables are considered for comparisong; they respectively represent the type, the label, 
	the format, the informat, the length and the position; by default, `typ=yes` while all others are 
	set to `no`.

### Returns

### Examples
Run macro `%%_example_var_compare` for more examples.

### See also
[%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info), [%var_rename](@ref sas_var_rename), 
[%ds_order](@ref sas_ds_order), [%var_count](@ref sas_var_count),
[VARNUM](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148439.htm),
[VARTYPE](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148443.htm),
[VARLABEL](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148456.htm),
[VARFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148399.htm),
[VARLEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148433.htm),
[VARINFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148419.htm),
[VFORMAT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000245971.htm),
