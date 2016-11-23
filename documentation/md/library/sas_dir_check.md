## dir_check {#sas_dir_check}
Check the existence of a directory.

	%let ans=%dir_check(dir);

### Arguments
* `dir` : a full path directory.

### Returns
`ans` : error code of the test of existence, _i.e._:
		+ `0` when the directory exists (and can be opened), or
    	+ `1` (error) when the directory does not exist, or
    	+ `-1` (error) when the directory exists but cannot be opened.

### Example
Just try on your "root" path, so that:

	%let ans=&dir_check(&G_PING_ROOTPATH);

will return `ans=0`.

Run macro `%%_example_dir_check` for more examples.

### See also
[%ds_check](@ref sas_ds_check), [%lib_check](@ref sas_lib_check), [%file_check](@ref sas_file_check),
[FEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210817.htm),
[FILENAME](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210819.htm),
[DOPEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209538.htm).
