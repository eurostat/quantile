## file_check {#sas_file_check}
Check the existence of a file given by its name. If required, also possibly check the format.

	%let ans=%file_check(fn, ext=);

### Arguments
* `fn` : full path and name of external file (!not a fileref!);
* `ext` : (_option_) string representing the extension of desired format (_e.g._, `csv`); 
  	     if not set, the format of the file is not verified.
  
### Returns
`ans` : error code associated to test, _i.e._:
	+ `0` if the file exists (with the right format when `ext` is not empty), or
    + `1` if the file does not exist, or
    + `-1` if the file exists but the format is not the one specified by `ext`.

### Example
Let us consider the file where this macro is defined, and check it actually exists:
	
	%let fn=&G_PING_LIBAUTO/file_check.sas;
	%let ans=%file_check(&fn, ext=SAS);

returns `ans=0`, while:

	%let ans=%file_check(&fn, ext=TXT);
	
returns `ans=-1`.

Run macro `%%_example_file_check` for more examples.

### Note
In short, the error code returned when `ext` is not set is the evaluation of:

	1 - %sysfunc(fileexist(&fn))

### Reference
1. ["Check for existence of a file"](http://support.sas.com/kb/24/577.html).
2. Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%dir_check](@ref sas_dir_check), [%lib_check](@ref sas_lib_check), [%file_copy](@ref sas_file_copy), 
[%file_delete](@ref sas_file_delete), [%file_name](@ref sas_file_name), [%file_ls](@ref sas_file_ls),
[FILEEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210912.htm).
