## dir_ls {#sas_dir_ls}
Generate a dataset with the names of all files in a directory or directory tree.
Wildcards may be used to specify the files to be included.

	%dir_ls(dir, dsn=, recur=no, lib=);

### Arguments
* `dir` : a directory full path, or file group (possibly containing wildcards) with full 
	path;
* `recur` : (_option_) flag of boolean type (`yes/no`) set to `yes` when search will
	be recursively performed in subdirectories;
* `lib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used.

### Returns
`dsn` : (_option_) output dataset created in `lib` library; this dataset contains three 
	fields, respectively:
		+ `base` for file name), and
		+ `path` for absolute path (path separator is slash '/'), and 
		+ `last` for last modification data as SAS datetime;

	when not set, a default dataset `WORK.dir_ls` is created with all the fields above.

### Example
The call to the following:

	%let dir=%quote(&EUSILC/library/data/);
	%dir_ls(&dir*csv, dsn=test);

stores in the `WORK.test` dataset the list (`base`+`path`+`last`) of CSV files present in the `dir` 
folder.

Run macro `%%_example_dir_ls` for more examples.

### Note
1. As for now, *this macro runs on Linux/Unix machines only*. Consider using [%file_ls](@ref sas_file_ls)
on other platforms.
2. In short, this macro launches a bash (Xcmd) request based on `find` of the given directory. 

### See also
[%file_ls](@ref sas_file_ls), [%dir_check](@ref sas_dir_check), [%file_name](@ref sas_file_name), 
[%SYSEXEC](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a000171045.htm).
