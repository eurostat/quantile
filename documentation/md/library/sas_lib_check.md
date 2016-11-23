## lib_check {#sas_lib_check}
Check the existence of a library.

	%let ans=%lib_check(lib);

### Argument
`lib` : library reference.

### Returns
`ans` : the error code of the test, _i.e._:
		+ `0` if the library reference exists,
    	+ `> 0` (error: "lib does not exist") if the library reference does not exist,
		+ `< 0` (error) if the library reference exists, but the pathname is in question. 

The latter case can happen when a `LIBNAME` statement is provided a non-existent pathname or the physical path 
has been removed, the library reference will exist, but it will not actually point to anything.

### Note
In short, the error code returned is the evaluation of:

	%sysfunc(libref(&lib));

### Reference
Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%dir_check](@ref sas_dir_check), [%file_check](@ref sas_file_check).
