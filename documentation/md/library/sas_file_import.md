## file_import {#sas_file_import}
Import (convert) a file from any format accepted by `PROC IMPORT` into a SAS dataset.

	%file_import(ifn, idir=, fmt=csv, _ods_=, olib=, getnames=yes);

### Arguments
* `ifn` : file name to import;
* `fmt` : (_option_) format for import, _i.e._ extension of the input file; it can be any format 
	(_e.g._, csv) accepted by the DBMS key in `PROC import`;
* `idir` : (_option_) input directory where the file is stored; default: the current location
	of the file
* `olib` : (_option_) output  library where the dataset will be stored; by default, `olib=WORK` 
    is selected as output library;
* `getnames` : boolean flag (`yes/no`) set to import the variable names; default: `getnames=yes`.
 
### Returns
`_ods_` : (_option_) name (string) of the macro variable storing the name of the output dataset.
 
### Notes
1. There is no format/existence checking, hence if the output selected type is the same as 
the type of the input dataset, or if the output dataset already exists, a new dataset will be 
produced anyway. If the `REPLACE` option is not specified, the `PROC IMPORT` procedure does 
not overwrite an existing data set.
2. In debug mode (_e.g._, `G_PING_DEBUG=1`), the import process is aborted; still it can checked
that the output dataset will be created with the correct name and location using the option 
`_ods_`. Consider using this option for checking before actually importing. 

### Example
Run macro `%%_example_file_import` for examples.

### Note
Variable names should be alphanumeric strings, not numeric values (otherwise converted).

### See also
[%ds_export](@ref sas_ds_export), [%file_check](@ref sas_file_check),
[IMPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000308090.htm).
