## file_name {#sas_file_name}
Return the basename, extension or library (directory) of a given dataset.

	%let name=%file_name(path, res=file);

### Arguments
* `path` : full path of a file (_e.g._, a SAS file);
* `res` : (_option_) string representing the result to output; it is either `ext` for
	the extension of the dataset (_e.g._, `sas7bdat`), or `dir` for the directory/library
	where the dataset is stored, or `base` (default when res is not passed) for the 
	basename of the dataset to be returned, or `file` for the complete filename without
	its path (_i.e._, both basename and extension concatenated together when the extension
	is present, the basename only otherwise); default: `res=file`, _i.e._ the filename is
	returned.
  
### Returns
`name` : desired output string depending on input `res` value. 

### Examples
Let us consider the file where this macro is defined, then the operation:

	%let fn=&G_PING_LIBAUTO/file_name.sas;
	%let name=%file_name(&fn, res=base);

returns `name=file_name` for instance, while:

	%let name=%file_name(&fn, res=dir);

returns `name=&G_PING_LIBAUTO`, and:

	%let name=%file_name(&fn, res=file);

returns `name=file_name.sas`.

Run macro `%%_example_file_name` for more examples.

### Note
* There is no test of the actual existence of any file associated to the considered path. 
* The directory returned (_i.e._ when `res=dir`) is always a path without the final '/'; in the case
a simple basename is passed, an empty directory path is returned.

### See also
[%file_check](@ref sas_file_check).
