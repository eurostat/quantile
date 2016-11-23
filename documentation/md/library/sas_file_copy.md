## file_copy {#sas_file_copy}
Copy a file byte by byte.

	%file_copy(ifn, ofn);

### Arguments
* `ifn` : full path and name of the input file to copy (!not a fileref!);
* `ofn` : ibid with the output copy file (!not a fileref!).
  
### Note
No error checking.

### Example
Run macro `%%_example_file_copy` for examples.

### See also
[%file_check](@ref sas_file_check), [%file_delete](@ref sas_file_delete).
