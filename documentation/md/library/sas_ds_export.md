## ds_export {#sas_ds_export}
Export (convert) a dataset to any format accepted by `PROC EXPORT`.

	%ds_export(ds, odir=, _ofn_=, fmt=csv, ilib=, delim=);

### Arguments
* `ds` : a dataset (_e.g._, a SAS file);
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%egp_path](@ref sas_egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise;
* `fmt` : (_option_) format for export; it can be any format (_e.g._, `csv`) accepted by
	the DBMS key in `PROC EXPORT`; default: `fmt=csv`;
* `ilib` : (_option_) input library where the dataset is stored; by default, `WORK` is 
	selected as input library;
* `delim` : (_option_) delimiter; can be any argument accepted by the `DELIMITER` key in 
	`PROC EXPORT`; default: none is used.
 
### Returns
`_ofn_` : name (string) of the macro variable storing the output exported file name.

### Notes
1. In short, this macro runs:

	   PROC EXPORT DATA=&ilib..&idsn OUTFILE="&odir./&idsn..&fmt" REPLACE
		   DBMS=&fmt
		   DELIMITER=&delim;
	   quit;

2. There is no format/existence checking, hence if the output selected type `fmt` is the same
as the type of the input dataset, or if the output dataset already exists, a new dataset 
will be produced anyway. Please consider using the setting `G_PING_DEBUG=1` for checking beforehand
actually exporting.
3. In debug mode (_e.g._, `G_PING_DEBUG=1`), the import export is aborted; still it can checked
that the output file will be created with the correct name and location using the option 
`_ofn_`. Consider using this option for checking before actually exporting. 

### Example
Run macro `%%_example_ds_export` for examples.

### See also
[%ds_check](@ref sas_ds_check), [%file_import](@ref sas_file_import),
[EXPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/a000393174.htm).
