## _dstestlib {#sas_dstestlib}
Test the prior existence of test dataset in `WORK` or test data directory.
	
	%_dstestlib(dsn, _lib_=);

### Argument
`dsn` : name of the test dataset; it is in general of the form: `"_dstestXX"` where
	`XX` defines the number of the test; in practice, `dsn` is passed to this macro
	from the calling macro using `&sysmacroname`.
  
### Returns
`_lib_` : in the macro variable whose name is passed to `_lib_`, the library (location) 
	of the dataset `dsn` whenever it already exists; it is either `WORK` or the default
	test data library (_e.g._, `&G_PING_TESTDB`).

### Note
This macro is not used 'as is', but it is generically called by all datatest macros of the
form `"_dstestXX". 

### See also 
[%ds_check](@ref sas_ds_check).
