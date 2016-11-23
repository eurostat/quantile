## file_delete {#sas_file_delete}
Delete a (external) file given by its name if it exists.

	%let rc=%file_delete(fn);

### Arguments
`fn` : full path and name of external file (!not a fileref!).
  
### Returns
`rc` : the error code of the operation, _i.e._:
		+ 0 if the file `fn` was correctly deleted,
    	+ system error code otherwise.

### Example
Run macro `%%_example_file_delete` for examples.

### See also
[%file_check](@ref sas_file_check), [%file_copy](@ref sas_file_copy).
