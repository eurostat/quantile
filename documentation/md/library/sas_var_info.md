## var_info {#sas_var_info}
Return information regarding a given variable in a dataset, _e.g._ the type of the
variable, its (in)format, its length, ...

	%var_info(dsn, var, _typ_=, _lab_=, _fmt_=, _len_=, _pos_=, _infmt_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : a field name whose information is provided;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
`_typ_, _lab_, _fmt_, _infmt_, _len_, _pos_` : names of the macro variables used to store the 
	output information about the variable in the dataset, respectively the type, the label, the 
	format, the informat, the length and the position of the variable.

### Examples
Let us consider the table `_dstest30`:
geo | value 
----|-------
 BE |  0    
 AT |  0.1  
 BG |  0.2  
 '' |  0.3 
 FR |  0.4  
 IT |  0.5 

then if we want to retrieve information about the variable `geo`, we use for instance:

	%let type=;
	%let len=;
	%let pos=;
	%let vfmt=;
	%var_info(_dstest30, value, _typ_=type, _len_=len, _pos_=pos, _vfmt_=vfmt);

which returns `pos=1, type=C, len=2, vfmt=BEST12`.

Run macro `%%_example_var_info` for more examples.

### See also
[%var_check](@ref sas_var_check), [%var_compare](@ref sas_var_compare), [%var_rename](@ref sas_var_rename), 
[%ds_order](@ref sas_ds_order), [%var_count](@ref sas_var_count),
[VARNUM](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148439.htm),
[VARTYPE](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148443.htm),
[VARLABEL](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148456.htm),
[VARFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148399.htm),
[VARLEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148433.htm),
[VARINFMT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148419.htm),
[VFORMAT](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000245971.htm),
