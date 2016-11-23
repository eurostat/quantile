/**
## macro_list {#sas_macro_list}
List all macros made available to a SAS session through SASAUTOS.

	%macro_list(work=no, dsn=, _maclst_=, lib=WORK, print=no);

### Argument
* `work` : (_option_) boolean flag (`yes/no`) set to list `WORK.SASMACR` entries; default: `work=no`.
* `lib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used;
* `print` : (_option_) boolean flag (`yes/no`) set to print the output on the log page; default:
	`print=no`.

### Returns
* `dsn` : (_option_) output dataset created in `lib` library; this dataset contains five fields, respectively:
		+ `path` for the absolute path of macro location (path separator is slash '/'), and 
		+ `member` for the macro/file name, and
		+ `catalog` for the name of the catalog the macro maypossibly be stored in (empty otherwise), and 
		+ `type` for the type of the macro (_e.g._, `.sas` for filenames, or `macro` for macros in catalog), 
		and
		+ `order` indicating the search order SAS uses;

 If intead your require the output to be stored in a file, use `print=no` above together with a `PROC PRINTTO` 
to reroute the output appropriately.
* `_maclst_` : (_option_) name of the macro variable where the list of SAS macro names as they appear in 
	 `member` (_i.e._, without extension)will be stored.

### Notes
1. **The macro `%%macro_list` is  a wrapper to H. Droogendyk's original `%%list_sasautos` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.stratia.ca/papers/list_sasautos.sas>. See reference below.
2. This macro prints the `.sas` member names of the various directories and filerefs returned by the 
`GETOPTION(SASAUTOS)` and `PATHNAME(SASAUTOS)` functions.  Also examines `WORK.SASMACR` and the 
`SASMACR` catalog referenced by the `PATHNAME(GETOPTION(SASMSTORE))`.
3. This macro may generate the following accepted warning:

       WARNING: Variable member has different lengths on BASE and DATA files

### Reference
Droogendyk, H. (2009): ["Which SASAUTOS macros are available to my SAS session?"](http://support.sas.com/resources/papers/proceedings09/076-2009.pdf)
([presentation](http://www.sas.com/content/dam/SAS/en_ca/User%20Group%20Presentations/TASS/Droogendyk-AvailableSASAUTOSMacros.pdf)).

### See also
[%macro_exist](@ref sas_macro_exist),
[%list_sasautos][http://www.stratia.ca/papers/list_sasautos.sas].
*/ /** \cond */

%macro macro_list(work=no 	/* Boolean flag set to list WORK.SASMACR entries 	(OPT) */
				, dsn=		/* Ouput dataset 									(OPT) */
				, _maclst_=	/* Name of the output list storing the macro names 	(OPT) */
				, lib=		/* Output library 									(OPT) */
				, print=no	/* Boolean flag set to print the outputs in the log (OPT) */
				, help=		/* Hidden flag 										(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%local i		/* loop counter */
		SEP			/* arbitrary list separator */
		tmp_f 		/* flag of temporary dataset */
		_maclst 	/* temporary list of macro names with the "sas" extension */	
		_nmaclst	/* ibid, without the "sas" extension; returned as output */
		_mac;		/* temporary macro name without the "sas" extension */
	/* initialisations */
	%let _nmaclst=;
	%let tmp_f=yes;

	/* check the output dataset */
	%if %macro_isblank(lib)	%then %let lib=WORK;
	%if not %macro_isblank(dsn)	%then %do;
		%let tmp_f=no;
		%if %error_handle(WarningOutputDataset, 
				%ds_check(&dsn, lib=&lib) NE 0, mac=&_mac,		
				txt=%quote(! Output dataset %upcase(&dsn) already exists - Will be overwritten !!!)) %then
			%goto warning;
		%warning:
	%end;
	
%put in &sysmacroname : dsn=&dsn, lib=&lib;

	/* check the work, print and help parameters */
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&work), type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong input WORK value found: %upcase(&work) - Must be boolean yes/no flag !!!)) %then
		%goto exit;
	%else %if not %macro_isblank(help) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(%upcase(&help), type=CHAR, set=? HELP) NE 0, mac=&_mac,		
				txt=%quote(! Flag %upcase(&help) ignored !, verb=warn)) %then %do;
			%let help=;
		%end;
	%end;
	%else %if not %macro_isblank(print) %then %do;
		%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&print), type=CHAR, set=YES NO) NE 0, mac=&_mac,		
				txt=%quote(! Flag %upcase(&print) ignored !, verb=warn)) %then %do;
			%let print=no;
		%end;
	%end;

	/* check the output list of macros: in that case we also need to retrieve the dataset */
 	%if not %macro_isblank(_maclst_) and %macro_isblank(dsn) %then
		%let dsn=TMP_&sysmacroname;

	%if %upcase(&work)=YES %then 	%let work=Y;
	%else							%let work=N;

	/* here is the macro from Droogendyk, H. with slight modifications regarding input parameters */
	%macro _list_sasautos(work=Y, dsn=, lib=, help=);

		%if "&help" = "?" or %upcase("&help") = "HELP" %then %do;
			%put;
			%put %nrstr(%list_sasautos(work=Y););
			%put;
			%put %nrstr(Lists the .sas files and catalog source/macro objects found within directories surfaced by:);
			%put %nrstr(   - getoption('sasautos') 			- SASAUTOS altered by options statement);
			%put %nrstr(   - pathname('sasautos')   			- config file SASAUTOS definition);
			%put %nrstr(   - filerefs / catalogs found within SASAUTOS definitions);
			%put %nrstr(   - pathname(getoption('sasmstore'))	- compiled macros.);
			%put ;
			%put %nrstr(If &work=Y ( default ), compiled macros from the WORK library will be included as well.);
			%put ;
			%put %nrstr(NOTE: Not every .sas / source module found within these directories is );
			%put %nrstr(NOTE: NECESSARILY a macro definition.  %list_sasautos does NOT open up );
			%put %nrstr(NOTE: objects to verify the presence of the required %macro statement.);
			%put ;
			%put %nrstr(In addition to the OUTPUT report ( use ODS for fancier report formats ), );
			%put %nrstr(results are also available in the WORK._LIST_SASAUTOS dataset.);
			%put;
			%goto exit;
		%end;

		/* work.sasmacr and the sasmacr catalog found at the SASMSTORE location 
		* are the first searched.  If &WORK=Y, grab the path info for the work 
		* directory.  If the SASMSTORE option is set, surface the path information
		* for that library.  We'll include at the front of the concatenation since
		* reflects the search order SAS uses. */

		%if "&dsn"= %then %let dsn=TAB&sysmacroname;
		%if "&lib"= %then %let lib=WORK;
	
%put in &sysmacroname : dsn=&dsn, lib=&lib;

		%if %upcase("&work") = "Y" and %sysfunc(cexist(work.sasmacr)) %then
			%let work_lib = %unquote(%str(%')%sysfunc(pathname(work))%str(%'));
		%else
			%local work_lib;

		%let sasmstore = %sysfunc(getoption(sasmstore));
		%if &sasmstore ne %str() %then %do;
			%let sasmstore = %sysfunc(pathname(&sasmstore));
			%if %bquote(&sasmstore) ne %str() %then
				%let sasmstore = %unquote(%str(%')&sasmstore%str(%'));
		%end;

		DATA &lib..&dsn ( keep = path member order type catalog );

			if substr(upcase("&sysscp"),1,3) = 'WIN' then
				s = '\';
			else
				s = '/';

			length pathname	
				sasautos	$32000
				path		
				chunk	
				option	$2000
				member 	$200
				catalog 	$32
				type		$8
				;

			label path			= 'O/S Path'
				member		= 'Macro / Filename'
				type			= 'Object Type'
				catalog		= 'Catalog Name'
				order			= 'Resolution Order'
				;

			catalog		= ' ';										/* to avoid not initialized msg */
			option 		= compress(getoption('sasautos'),'()');		/* get SASAUTOS option value		*/

			/* Grab space-delimited SASAUTOS definitions.  Entries that are file system paths will be 
			* captured and file references, SASAUTOS and catalog references will be expanded. 	*/

			do i = 1 to &sysmaxlong until ( scanq(option,i,' ') = ' ' );	
				chunk = compress(scanq(option,i,' '),"'");

				if indexc(chunk,':/\') then do;			
					/* if path delimiters found, pass straight in  */
					sasautos 				= catx(' ', sasautos, chunk );
				end; else do;							
					/* no path delimiters found, expand the entry to the path level  */
					pathname = compress(pathname(chunk),'()');
					if pathname > ' ' then do;

					if pathname =: '..' then do;				
						/* catalog libname starts with ..  */
						cat_pathname	= substr(pathname,3);	/*  skip over two dots  */
						/*  Since we have catalog name, insert it in the path with surrounding single quotes  */
						path 			= pathname(scan(trim(cat_pathname),1,'.')) || s || scan(trim(cat_pathname),2,'.') || '.SAS7BCAT';
						sasautos 		= catx(' ', sasautos, "'"||trim(path)||"'" );

					end; else do;		
						/* must have SASAUTOS or a file reference, SASAUTOS paths start with a single quote */
						if left(pathname) =: "'" then 
							sasautos 	= catx(' ', sasautos, compress(pathname,'()'));			/* sasautos */
						else 
							sasautos 	= catx(' ', sasautos, "'"||trim(pathname)||"'");		/* fileref 	*/
						end;
					end;
				end; 				
			end; /* end of "do i = 1 to &sysmaxlong until ..." */

			/* If we're going after WORK and COMPILED STORED macros, add their paths at
			* the front since that's the search order SAS uses  */

			sasautos = left("&work_lib &sasmstore " || translate(sasautos,"'",'"'));

			put / 'Processing: ' option= // sasautos= ;

			cat 	= 0;
			order 	= 0;

			/* Chew through the fleshed out list of paths / catalogs.  We added quotes to paths in some cases
			* so we could use the scanq below.  However, we want to remove them before we use the path */

			do i = 1 to &sysmaxlong until ( scanq(sasautos,i,' ') = ' ' );	
				path = compress(scanq(sasautos,i,' '),"'");
				/* Where the fileref pointed to a SAS catalog, we have specified the SAS7BCAT suffix to ensure we
				* pick up only the specified catalog at this path.  Since we're processing catalogs in more than
				* one spot, we're using a common routine
				*/

				if scan(path,-1,'.') = 'SAS7BCAT' then do;		
					member 	= scan(path,-1,s);
					path 	= substr(path,1,length(path)-length(member)-1);
					link do_cat;	/* catalog identified via fileref 						*/
				end; else do;		/* if it ain't a catalog, it must be a directory		*/
					problem = filename('dir',trim(path));		/* create a fileref pointing to dir */
					if problem then do;
						put 'Cannot open filename for ' path;
					end; else do;
						d = dopen('dir');				/* open the directory				*/
						if d then do;					/* directory successsfully open?  	*/
							num = dnum(d);				/* number of files in directory 	*/
							do _i = 1 to num;				/* loop through files in directory					*/
						    	member 	= dread(d,_i);		/* get next filename in directory					*/
								/* Try to append the member name to the end of the path and open it as a directory,
								* if that's successful, we don't want it, ie. we only want real files 		*/
								dir_example_file 	= filename('dir_test',cats(path,s,member));
								if dir_example_file then continue;		* cannot assign filename to this file, iterate loop ;
								dtf = dopen('dir_test');
								if dtf then do;
									rc = dclose(dtf);
									continue;						* file opened as a sub-directory, iterate loop ;
								end;
								if upcase(scan(member,-1,'.')) = 'SAS7BCAT' then do;	
									link do_cat;		/* found a catalog in the directory, deal with it   */
								end; else do;
									if upcase(scan(member,-1,'.')) = 'SAS' then do;		/* .sas member ? */
										order 	+ 1;
										type	= '.sas';
										output;
									end; 
								end;
							end;
							rc = dclose(d);					/* close the directory we've opened */
						end;
					end;
				end; /* end of "if scan(path,-1,'.') =..." */
			end; /* end of "do i = 1 to &sysmaxlong until ..." */

			call symputx('no_of_cats',cat);	 /* save the number of catalogs found for macro loop below  */

			return;

			/* This code is specified here and LINKed to from two different places.  NOT using sashelp.vcatalog
			* because it just got toooooo complicated because I don’t have the libname.  Gets complicated with
			* compiled macros.  We’re getting catalog details in the following step. */

			do_cat:
				cat 	+ 1;
				order 	+ 1;
				call symput ('path'||put(cat,3.-l),trim(path));
				call symput ('cat'||put(cat,3.-l),substr(member,1,length(member)-9)); * take off .sas7bcat; 
				call symputx('order'||put(cat,3.-l),order);
			return;

		run;

		/* Now unpack the contents of the macro/source catalogs, working our way 
		* through the macro variables created in the previous step.  Routing
		* source/macro contents of the catalog to an OUT dataset. */

		%do i = 1 %to &no_of_cats;
			%put Processing catalog &&cat&i in &&path&i;
			libname _c "&&path&i";
				
			PROC CATALOG catalog = _c.&&cat&i;
				CONTENTS out = _cat_contents ( keep = memname name type 
											  where = ( type in ( 'SOURCE', 'MACRO' ) ));
			quit;

			DATA _null_;
				if 0 then set _cat_contents nobs = nobs ;
				call symputx('_cat_contents_nobs',nobs);
				stop;
			run;

			%if &_cat_contents_nobs > 0 %then %do;
				/*  Flesh out the details  */
				DATA _cat_contents;
					SET _cat_contents ( rename = ( name = member memname = catalog ));
					length path $2000;
					path 	= "&&path&i";
					catalog	= "&&cat&i";
					order 	= &&order&i;
					type	= lowcase(type);	* prefer lowercase ;
				run;

				/*  Append to those we've found already  */
				PROC APPEND base = &lib..&dsn
					data = _cat_contents force;
				run;
				/* note that this PROC may generate a warning of the type: 
					WARNING: Variable member has different lengths on BASE and DATA files
				when both datasets have character variables of different lengths; the FORCE
				option enables the program to run anyway.
				See also http://www2.sas.com/proceedings/sugi28/098-28.pdf
				*/
			%end;

			libname _c clear;
		%end;
		%work_clean(_cat_contents);

		/*  it's possible that duplicate paths are in the SASAUTOS definition, weed out dups here  */
		PROC SORT data = &lib..&dsn;
			BY path member order;
		run;

		/*  sorted by "order" so we'll keep the earliest one found in concatenation  */
		PROC SORT data = &lib..&dsn	nodupkey ;
			BY path member;
		run;

		/*  sort the list by member name and the order the macro was found  */
		PROC SORT data = &lib..&dsn;
			BY member order;
		run;

		%exit:
	%mend _list_sasautos;

	/* run the macro */
	%_list_sasautos(work=&work, dsn=&dsn, lib=&lib, help=&help);

%put in &sysmacroname : dsn=&dsn, lib=&lib;

 	%if not %macro_isblank(_maclst_) %then %do;
		%put ENTER HERRRRRRRRRRRRRRRRRRRRRRRRRE;
		%let SEP=%str( );
		%var_to_list(&dsn, member, _varlst_=_maclst, sep=&SEP, lib=&lib);
		%put EXIT HERRRRRRRRRRRRRRRRRRRRRRRRRE;
		%put _maclst=&_maclst;
		%put %list_length(&_maclst, sep=&SEP);
		%let _nmaclst=;
		%do i=1 %to %list_length(&_maclst, sep=&SEP);
			%let _mac=%file_name(%list_index(&_maclst, &i, sep=&SEP), res=base);
			%put read _mac=&_mac;
			%let _nmaclst=&_nmaclst.&SEP.&_mac;
		%end;
		/*data _null_;
			call symput("&_maclst_","&_nmaclst");
		end;*/
	%end;

	%if not %macro_isblank(print) and %upcase("&print") = "YES" %then %do;
		PROC PRINT data=&lib..&dsn noobs;
			VAR order member path type catalog;
			FORMAT _character_;
		run;
	%end;

 	%if tmp_f=yes %then %do;
		; /*%work_clean(&dsn); /* it was for sure created in the WORK library */
	%end;

	%exit:
%mend macro_list;

%macro _example_macro_list;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%macro_list(help=HELP);

	%local dsn maclst;
	%let dsn=TMP&sysmacroname;

*	%macro_list(work=Y, dsn=&dsn, print=yes);
	%macro_list(work=Y, dsn=&dsn, /*_maclst_=maclst,*/ print=yes);
	%put maclst=&maclst;

	%ds_print(&dsn);

	%put;

	%*work_clean(&dsn);
%mend _example_macro_list;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
*/
%_example_macro_list; 

/** \endcond */
