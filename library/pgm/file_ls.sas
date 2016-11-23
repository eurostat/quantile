/**
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
*/
/** \cond */ 

%macro file_ls(dir			/* Full path of input directory 											(REQ) */
			, match=		/* Pattern to search/match with the filename strings 						(OPT) */
			, ext=			/* Extension of filename 													(OPT) */
			, beg=NO		/* Boolean flag set to match pattern at the beginning of the file/dirname 	(OPT) */
			, end=NO		/* Boolean flag set to match pattern at the end of the file/dirname 		(OPT) */
			, casense=YES	/* Boolean flag set for case sensitive matching 							(OPT) */
			, excldir=NO	/* Boolean flag set for subdirectories exclusion from search				(OPT) */
			);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* test the consistency of input parameters */
	%if %macro_isblank(beg) %then 		%let beg=NO;
	%if %macro_isblank(end) %then 		%let end=NO;
	%if %macro_isblank(casense) %then 	%let casense=YES;
	%if %macro_isblank(excldir) %then 	%let excldir=NO;

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&casense), type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter CASESENS is boolean flag with values in (yes/no) !!!)
		or
		%error_handle(ErrorInputParameter, 
			%par_check(%upcase(&beg &end), type=CHAR, set=YES NO) NE %quote(0 0), mac=&_mac,	
			txt=!!! Parameters BEG and END are boolean flags with values in (yes/no) !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local n		/* loop counter */
		_memb 		/* temporary file/dirname */
		_isdir		/* flag for directory */
		_ind 		/* position/index of match in _file */
		_indext		/* position/index of extension in _file */
	  	_rc 		/* temporary filename code */
		_fref 		/* temporary file reference */
		_did 		/* temporary dopen code */
		_lenext 	/* length of extension */
		_lenpat		/* length of matching pattern */
		_len 		/* length of filename */
		_memcount	/* memcount of number of files */
		_base; 		/* output */

	%let _base=; /* set already in case we exit the macro very soon... */

	/* assign fileref _fref to the physical directory stored in dir */
    %let _fref=_TMPFILE;
	%let _rc = %sysfunc(filename(_fref, &dir)) ;

	/* test that the directory exists */
	%if %error_handle(ErrorInputParameter, 
			%sysfunc(fexist(&_fref)) EQ 0,		
			txt=!!! Directory %upcase(&dir) does not exist !!!) %then
		%goto exit;
	/* %else: directory exists, proceed... */

	/* test that the directory opens */
	%let _did=%sysfunc(dopen(&_fref));
	%if %error_handle(ErrorInputParameter, 
			&_did EQ 0,		
			txt=!!! Directory %upcase(&dir) does not open !!!) %then
		%goto quit;
	/* %else: directory opened successfully, proceed... */
	
	/* lengths of pattern and extension */
	%if not %macro_isblank(match) %then	
		%let _lenpat=%length(&match);
	%if not %macro_isblank(ext) %then
		%let _lenext=%length(&ext);

	/* retrieve the number of members in directory */
	%let _memcount = %sysfunc(dnum(&_did)) ;
	%if &_memcount = 0 %then
		/* nothing found: exit ... */
		%goto quit;

	/* loop over all members */
	%do n = 1 %to &_memcount;
		%let _memb = %sysfunc(dread(&_did, &n));
		%let _len=%length(&_memb);
		/* %let _memb=%file_name(&file, res=base); */

		/* basic test on the member */
		%let _isdir=%sysfunc(mopen(&_did, &_memb));
		/* note that mopen return 0 for a directory, a <>0 value otherwise */
		%if %upcase("&excldir")="YES" and &_isdir = 0 %then 
			%goto next; /* member is a directory: test next member */

		%if not %macro_isblank(match) %then %do;
			/* check the matching index of pattern in the filename */
			%if &sysscp ^= WIN /* case unsensitive shitty Windows */
					or
					%upcase("&casense")="NO" /* we explicitely requested to be case unsensitive */ %then 
				%let _ind=%index(%upcase(&_memb),%upcase(&match));
			%else 
				%let _ind=%index(&_memb,&match);

			%let _indext=%index(&_memb,.); /* position of the '.' preceding the extension */

			%if &_ind<= 0 
					/* no match, pattern was not found in the filename: test next member */
				 	or
					%upcase("&beg")="YES" and &_ind>1 
					/* pattern was not found at the beginning of the filename: test next member */
					or 
					%upcase("&end")="YES" and %sysevalf(&_ind+&_lenpat^=&_indext) %then 
					/* pattern does not match the end of the filename: test next member */
				%goto next;
		%end;

		%if not %macro_isblank(ext) %then %do ;
			%if %upcase(%substr(&_memb, %eval(&_len-&_lenext), %eval(&_lenext+1))) = %upcase(.&ext) %then
				%let _memb = %substr(&_memb, 1, %eval(&_len-&_lenext-1)) ;
			%else %goto next;
		%end;
		/* %else: no change on _memb name, use as is */

		%let _base = &_base &_memb;
		%next:
	%end;

	%quit:
	/* we need to close the dirref */
	%let _rc = %sysfunc(dclose(&_did)); 

	%exit:
	/* we need to deassign the fileref */
	%let _rc = %sysfunc(filename(_fref)) ;
	/* return  the (possibly empty) list of files */
	&_base
%mend file_ls;


%macro _example_file_ls;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dir ext pattern ores;

	%let dir=&G_PING_ROOTPATH/Certainly_does_not_exist_directory/;
	%put;
	%put (i) Look for files into this dummy directory: %upcase(&dir);
	%put dir=&dir;
	%if %macro_isblank(%file_ls(&dir)) %then 	%put OK: TEST PASSED - Dummy directory: empty list returned;
	%else 										%put ERROR: TEST FAILED - Dummy directory: non-empty list returned;

	%let dir=&G_PING_ROOTPATH/library/autoexec; /*G_LIBAUTO*/
	%put;
	%let pattern=Certainly_does_not_exist_file;
	%put (ii) Look for an unexisting file into this directory: %upcase(&dir);
	%if %macro_isblank(%file_ls(&dir, match=&pattern)) %then 	%put OK: TEST PASSED - Dummy directory: empty list returned;
	%else 										%put ERROR: TEST FAILED - Dummy directory: non-empty list returned;

	%let casense=NO;
	%let dir=&G_PING_ESTIMATION/config; /* G_PING_LIBCONFIG */
	%if %symexist(G_PING_INDICATOR_CODES_RDB) %then 	%let pattern=&G_PING_INDICATOR_CODES_RDB; 
	%else 												%let pattern=INDICATOR_CODES_RDB; 
	%put;
	%put (iii) Search for the file(s) with &pattern (not case sensitive) in directory: %upcase(&dir);
	%let ores=&pattern..csv &pattern.2.csv;
	%let res=%file_ls(&dir, match=&pattern, casense=&casense);
	%if %upcase(&res) = %upcase(&ores) %then 	%put OK: TEST PASSED - File retrieved: &ores;
	%else										%put ERROR: TEST FAILED - Wrong files retrieved: &res;

	%let casense=NO;
	%let end=YES;
	%put;
	%put (iv) Same search with end=&end;
	%let ores=&pattern..csv;
	%let res=%file_ls(&dir, match=&pattern, end=&end, casense=&casense);
	%if %upcase(&res) = %upcase(&ores) %then 	%put OK: TEST PASSED - File retrieved: &ores;
	%else										%put ERROR: TEST FAILED - Wrong files retrieved: &res;

	%let ext=csv;
	%put;
	%put (v) Perform the same search but further passing the extension %upcase(&ext) to the macro;
	%let ores=&pattern; /* note the absence of the extension in the ouput list */
	%let res=%file_ls(&dir, match=&pattern, ext=&ext, end=&end, casense=&casense);
	%if %upcase(&res) = %upcase(&ores) %then 	%put OK: TEST PASSED - File retrieved: &ores;
	%else									%put ERROR: TEST FAILED - Wrong files retrieved: &res;

	%let dir=&G_PING_ROOTPATH/library/pgm;
	%let ext=sas;
	%let pattern=list;
	%put;
	%put (vi) Search for files matching pattern %upcase(&pattern) in directory %upcase(&dir);
	%let res=%file_ls(&dir, match=&pattern, ext=&ext);
	%if %list_find(%quote(&res), list_quote) and %list_find(%quote(&res), clist_unquote) %then 	
		%put OK: TEST PASSED - File list retrieved contains both %upcase(list_quote) and %upcase(clist_unquote);
	%else									
		%put ERROR: TEST FAILED - Wrong files list retrieved: &res;

	%let dir=&G_PING_ROOTPATH/library/pgm;
	%let beg=yes;
	%let ext=sas;
	%let pattern=list;
	%put;
	%put (vii) Same search, but also specify beg=%upcase(&beg) this time;
	%let res=%file_ls(&dir, match=&pattern, beg=&beg, ext=&ext);
	%if %list_find(%quote(&res), list_quote) and %macro_isblank(%list_find(%quote(&res), clist_unquote)) %then 	
		%put OK: TEST PASSED - File list retrieved contains %upcase(list_quote) but not %upcase(clist_unquote);
	%else									
		%put ERROR: TEST FAILED - Wrong files list retrieved: &res;

	%let dir=&G_PING_ANONYMISATION/PUF/data/AT/2012/; /*&G_PING_PUFDB/AT/2012*/
	%let ext=csv;
	%let pattern=puf;
	%put;
	%put (viii) Search for %upcase(&ext) file with pattern &pattern in directory: %upcase(&dir);
	%let ores=puf_p_SILC2012 puf_r_SILC2012 puf_d_SILC2012 puf_h_SILC2012;
	%let res=%file_ls(&dir, match=&pattern, ext=&ext);
	%if %quote(&res) = %quote(&ores) %then 	%put OK: TEST PASSED - Files retrieved: &ores;
	%else									%put ERROR: TEST FAILED - Wrong files retrieved: &res;

	%if &sysscp ^= WIN %then %do; /* note that %dir_ls works on non-Windows machines */
		%local dsn i tmp;
		%let dsn=TMP&sysmacroname;
		%let dir=%quote(&G_PING_ROOTPATH/library/pgm/);
		%let ext=sas;
		%let pattern=list;
		%put;
		%put (ix) Compare the output of %nrstr(%file_ls) with those of %nrstr(%dir_ls): retrieve all the %upcase(&ext) files from directory: %upcase(&dir);
		%let ores=;
		%dir_ls(&dir*&pattern*&ext, dsn=&dsn);
		%var_to_list(&dsn, base, _varlst_=tmp);
		%do i=1 %to %list_length(&tmp, sep=%str( ));
			%let ores=&ores %file_name(%scan(&tmp,&i,%str( )), res=base);
		%end;
		%if %list_compare(%file_ls(&dir, match=&pattern, ext=&ext), &ores) = 0 %then 	
			%put OK: TEST PASSED - Results match with those retrieved using %nrstr(%dir_ls);
		%else									
			%put ERROR: TEST FAILED - Results do not match with those retrieved using %nrstr(%dir_ls);
	%end;	

	%put;

	%work_clean(&dsn);
%mend _example_file_ls;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_file_ls;
*/

/** \endcond */
