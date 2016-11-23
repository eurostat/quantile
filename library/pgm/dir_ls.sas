/** 
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
*/ /** \cond */

%macro dir_ls(dir
			, dsn=
			, recur=no
			, lib=
			);
	%local _mac;
	%let _mac=&sysmacroname;

   	%local _enc
		_filedir 
		_fdir 
		_ldir 
		_dir
		k
		search;

	%if %error_handle(ErrorDatasetCreation, 
			&sysscp = WIN, mac=&_mac,		
			txt=%nrstr(!!! This macro does not run on Windows system - Use %file_ls instead !!!)) %then 
		%goto exit;

	/* initial check: if a folder was passed, add the wildcard */
	%if %dir_check(&dir)=0 %then %let dir=&dir%quote(/)*; 

	/* %else: do nothing */
	%if %macro_isblank(dsn) %then 	%let dsn=%upcase(&sysmacroname);
	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/* create already the output dataset in the WORK library */
	PROC SQL noprint;
    	CREATE TABLE &lib..&dsn (path char(255));
  	quit;

	%if %error_handle(ErrorDatasetCreation, 
			%ds_check(&dsn, lib=&lib) EQ 1,		
			txt=!!! Output dataset could not be created !!!, mac=&_mac) %then 
		%goto exit;

	/* create a temporary file */
	%let _fdir=%sysfunc(pathname(work))/&dsn._dir.txt;

	%let _enc=pcoem850; /*wlatin1*/
   	filename _filedir "&_fdir" encoding=&_enc;

	/* manipulation of the path string */
	%let _ldir=%qsysfunc(tranwrd(&dir, %str( ), %str(\ )));

   	%let search = %qscan(&_ldir.,-1,'/');
   	%let k = %index(&_ldir.,%qtrim(&search.));
   	%let _dir = %qsubstr(&_ldir.,1,%eval(&k.-2));
   	%if %qsubstr(&_dir.,1,1) eq %str(%') %then
    	%let _dir = &_path.%str(%');
   	%if %qsubstr(&_dir.,1,1) eq %str(%") %then
       	%let _dir = &_path.%str(%");

	/* actual search through find command */
   	%sysexec(find -L &_dir. ! -name &_dir -name "&search." -ls -type f > &_fdir.);

	%if %error_handle(ErrorDatasetCreation, 
			%file_check(&_fdir) NE 0, mac=&_mac,		
			txt=!!! Temporary file %upcase(&_fdir) not written !!!) %then 
		%goto exit;

	/* store the output (basename+paths+last updates) in the dataset */
   	data &lib..&dsn (keep=base path last);
      	array dum{7} $;
      	array dat{3} $;
      	length path base $255
        %if &recur=yes %then %do;
        	temp_path temp_file $255
       	%end;
        	fileall  $1024;
      	format last datetime20.;
      	infile _filedir delimiter=' ' truncover;
      	input dum1-dum7 $ dat1-dat3 $ fileall $;
      	path = fileall;
      	if substr(dum3,1,1)='d' then delete;
      	if index(dat3,':') gt 0 then do;
         	last = input(compress(dat2 || dat1 || year(today())) || " " || dat3, datetime.);
         	if datepart(last) gt today() then do;
            	last = input(compress(dat2 || dat1 || year(today())-1) || " " || dat3, datetime.);
         	end;
      	end;
      	else do;
         	last =input(compress( dat2 || dat1 || dat3) || " 00:00", datetime.);
      	end;
      	loca = length(path) - length(scan(path,-1,'/')) + 1;
      	base = substr(path,loca);

      	%if &recur=yes %then %do;
         	temp_path = dequote("&_dir");
         	temp_file = scan(path,-1,"/");
         	if (trim(temp_path) !! "/" !! trim(temp_file) = path) then output;
      	%end;
   	run;

	/* remove temporary file */
   	%sysexec(rm -f &_fdir.);

	%exit:
%mend dir_ls;


%macro _example_dir_ls;
	%if &sysscp = WIN %then %goto exit;

	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn dir;
	%let dsn=test;

	%put (i) Retrieve all files from a given folder;
	%let dir=%quote(&G_PING_ROOTPATH/library/pgm);
	%dir_ls(&dir, dsn=&dsn);
	%ds_print(&dsn);

	%put (ii) Retrieve only files with specific format: a wildcard is used;
	%let dir=%quote(&G_PING_ROOTPATH/library/data/);
	%dir_ls(&dir*csv, dsn=&dsn);
	%ds_print(&dsn);

	%put;
%mend _example_dir_ls;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dir_ls;  
*/

/** \endcond */
