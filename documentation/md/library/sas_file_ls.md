## file_ls {#sas_file_ls}
Return the names of all files member of a given directory.

    %let list = %file_ls(dir, match=, nomatch=, ext=, beg=no, end=no, casense=yes, excldir=no);

### Arguments
* `dir` : a directory full path;
* `match` : (_option_) inclusion pattern for the name of the members (files and directories, also
	depending on parameter `excldir` below) `searched for; for instance, you may wish to list all 
	files starting with "table_" passing `match=table_`; default: empty, no pattern is defined, the 
	macro will search for all members without restriction;
* `nomatch` : (_option_) exclusion pattern for the name of the members searched for; NOT IMPLEMENTED 
	YET;
* `ext` : (_option_) extension of the members searched for; default: no extension, the macro will 
	search for all members without consideration for the extension;
* `beg` : (_option_) boolean flag (`yes/no`) set to force the matching of the `match` string at the 
	beginning of the filenames; default: `beg=no`, _i.e._ a match with the `match` string is looked 
	for anywhere in the filenames whenever `end=no` as well (see below);
* `end` : (_option_) ibid with the end of the filenames; `end` is incompatible with `beg` (see above); 
	default: `end=no`, _i.e._ a math with the `match` string is looked for anywhere in the filenames;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; 
	default: `casense=yes`, _i.e._ the pattern `match` will be searched/matched exactly;
* `excldir` : (_option_) boolean flag (`yes/no`) set to exclude subdirectories from the search; 
	default: `excldir=no`, _i.e._ sub-directories, when they exist, are also searched for (and matched 
	against	all search criteria above).

### Returns
`list` : list of the files member of the directory `dir` matching the constraints on `match` and/or
	`ext` when passed as parameters. 

### Examples
let us test the current file (`file_ls.sas`):

	%let dir=&G_PING_ROOTPATH/library/autoexec;
	%let ext=sas;
	%let pattern=file_ls;

then running:

	%let list=%file_ls(&dir, match=&pattern, ext=&ext);

returns `list=file_ls`, while running:

	%let list=%file_ls(&dir, match=&pattern);

returns `list=file_ls.sas`, and running:

	%let list=%file_ls(&dir);

returns in `list` the list of all files present in the directory `&G_PING_ROOTPATH/library/autoexec`. The options
`beg/end` can be further used to specified the type of matching, _e.g._:

    %let dir=&G_PING_ROOTPATH/library/autoexec;
    %let beg=yes;
	%let ext=sas;
	%let pattern=list;
	%let list=%file_ls(&dir, match=&pattern, beg=&beg, ext=&ext);

returns in `list` the list of all files present in the directory `&G_PING_ROOTPATH/library/autoexec` whose names 
start with the pattern `list`; in particular the file `list_quote` will be returned in `list`, but not 
`clist_unquote` will not.

Run macro `%%_example_file_ls` for more examples.

### Notes
1. This macro enables the user to list the files in a given folder, either SAS tables or any other types of 
files. This is typically useful when dealing with massive imports of CSV/txt files.
2. Note, like in the example above, that in the case you specify an extension `ext`, the macro automatically 
omits the extension in the output `list`. Otherwise, the name of the files are provided with their extensions.
3. In practice, the same identical output can be retrieved using the macro [%dir_ls](@ref sas_dir_ls) using the 
following commands:

    %let list=; 
    %let tmp=;
    %dir_ls(&dir*&pattern*&ext, dsn=TMP);
    %var_to_list(TMP, base, _varlst_=tmp);
    %do i=1 %to %list_length(&tmp, sep=%str( ));
         %let list=&list %file_name(%scan(&tmp,&i,%str( )), res=base);
    %end;
Note that, contrary to `%%dir_ls` that works only on non-Windows machines, *this macro runs on all 
platforms/systems*.
4. In the case that `beg=yes` and `end=yes`, the macro looks for filenames matching exactly `match`.

### References
Hamilton, J.(2012): ["Obtaining a list of files in a directory using SAS functions"](http://www.wuss.org/proceedings12/55.pdf).

### See also
[%dir_ls](@ref sas_dir_ls), [%dir_check](@ref sas_dir_check), [%file_name](@ref sas_file_name),
[FEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210817.htm),
[FILENAME](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210819.htm),
[DOPEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209538.htm),
[DNUM](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209695.htm),
[DREAD](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209687.htm).
