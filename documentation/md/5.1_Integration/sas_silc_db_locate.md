## silc_db_locate {#sas_silc_db_locate}
Locate the bulk database (pathname and datasets name) corresponding to given survey (cross-sectional, 
longitudinal or early), a period and/or a country.

	%silc_db_locate(survey, time, geo, db=, src=, 
					_ftyp_=, _ds_=, _path_=, 
					cds_transxyear=TRANSMISSIONxYEAR, clib=LIBCFG);

### Arguments
* `survey` : type of the survey; this is represented by any of the character values defined in the 
	global variable `G_PING_SURVEYTYPES`, _i.e._ as:
		+ `X`. `C` or `CROSS` for a cross-sectional survey,
		+ `L` or `LONG` for a longitudinal survey,
		+ `E` or `EARLY` for an early survey,
* `time` : a single selected year of interest; 
* `geo` : string(s) representing the ISO-code(s) of (a) country(ies); by default, when `geo`is not 
	passed, the output parameters `_path_` and `_ds_` cannot defined: only `_ftyp_` can be returned
	(see below);
* `db` : (_option_) database(s) to retrieve; it can be any of the character values defined through 
	the global variable `G_PING_BASETYPES`, _i.e._:
		+ `D` for household register/D file,
		+ `H` for household/H file,
		+ `P` for personal register/P file,
		+ `R` for register/R file,
	so as to represent the corresponding bulk databases (files); by default,`db=&G_PING_BASETYPES`; 
* `src` : (_option_) string defining the source location where to look for bulk database; this can 
	be either the full path of the directory where to search in, or any of the following strings:
		+ `raw` so that the path of the search directory is set to the value of `G_PING_RAWDB`,
		+ `bdb`, ibid with the value of `G_PING_BDB`,
		+ `pdb`, ibid with the value of `G_PING_PDB`,
		+ `udb`, ibid with the value of `G_PING_UDB`;
	note that the latter three cases are independent of the parameter chosen for `geo`;	note also
	that `src=bdb` is currently incompatible with `survey<>X`; by default, `src` is set to the value 
	of `G_PING_RAWDB` (_e.g._ `&G_PING_ROOTPATH/main`) so as to look for raw data;
* `cds_transxyear, clib` : (_options_) configuration file storing the the yearly definition of
	microdata transmission files' format, and library where it is actually stored; for further 
	description of the table, see [%_transmissionxyear](@ref cfg_transmissionxyear).
 
### Returns
* `_ftyp_` : (_option_) longitudinal, cross-sectional or reconsilied/regular
* `_ds_` : (_option_) name(s) of the bulk dataset(s_ extracted from the databases in `db`; in 
	practice, all bulk datasets (files) have generic name of the form:
		+ `&ts.&yy.&db` when `src` is in (`pdb`,`udb`),
		+ `bdb_&ts.&yy.&db` when `src=bdb` (`bdb_c` available only),
		+ `&ts.&geo.&yy.&db` when `src=bdb`,

	where:
		+ `ts` is the type of the tranmission file whose definition depends on `survey` (_i.e., 
		either `C, L, E`, or `R`),
		+ `db` is any element of `db` (_i.e._, either `D, H, P`, or `R`),
		+ `geo` is any ISO-code represented in `geo`,
		+ `yy` is composed of the last two digits of a`time` (_i.e._, if `time=2014`, then `yy=14`)
	and are retrieved from the database library associated to `src`;
* `_path_` : (_option_) path to longitudinal, cross-sectional or reconsilied/regular database(s), 
	set depending on `src` value.

### Examples
Let us consider the following simple example:
	
	%let ftyp=;
	%silc_db_locate(X, 2014, _ftyp_=ftyp);

will return `ftyp=r` because cross-sectional data are normally transmitted via regular (R) files 
since 2014. We can further retrieve the location of the corresponding `H` file:

	%let ds=;
	%let path=;
	%silc_db_locate(X, 2014, geo=AT, db=H, _ds_=ds, _path_=path);

will set `path=/ec/prod/server/sas/0eusilc/main/at/r14` and `ds=rat14h`, while

	%let ds=;
	%let path=;
	%silc_db_locate(X, 2014, geo=AT DE, db=H, _ds_=ds, _path_=path);
	
will set `path=/ec/prod/server/sas/0eusilc/main/at/r14 /ec/prod/server/sas/0eusilc/main/de/c14` and 
`ds=rat14h cde14h`. It is then possible to retrieve the full paths:

	%let file=%list_append(&path,&ds, zip=%quote(/), rep=%quote( ));
	%let file=%list_append(&file, %list_ones(%list_length(&file), item=sas7bdat), zip=%quote(.));

sets `file=/ec/prod/server/sas/0eusilc/main/at/r14/rat14h.sas7bdat /ec/prod/server/sas/0eusilc/main/de/c14/cde14h.sas7bdat`.
Finally:

	%let ftyp=;
	%let ds=;
	%let path=;
	%silc_db_locate(X, 2014, geo=AT DE, db=R H, _ftyp_=ftyp, _ds_=ds, _path_=path);
sets `ftyp=r c`, `path=/ec/prod/server/sas/0eusilc/main/at/r14 /ec/prod/server/sas/0eusilc/main/at/r14
/ec/prod/server/sas/0eusilc/main/de/c14 /ec/prod/server/sas/0eusilc/main/de/c14` and 
`ds=rat14r rat14h cde14r cde14h`.

Run `%%_example_silc_db_locate` for more examples.

### Notes
1. The existence of returned path (in `_path_`) and dataset (in `_ds_`) is not verified.
2. In order to retrieve the type of the transmission file (returned through `_ftyp_`), this 
macro runs in practice:

	PROC SQL noprint;
		SELECT Y&time
		INTO :&_ftyp_
		%if %list_length(&geo)>0 %then %do;
			SEPARATED BY " "
		%end;
		FROM &clib..&cds_transxyear
		WHERE transmission="%upcase(&survey)" and
		%if %list_length(&geo)>0 and &src=raw %then %do;
			geo in (%list_quote(&geo))
		%end;
		%else %do;
			missing(geo)
		%end;
		;
	quit;
Following, to retrieve the common type `ftyp` of transmission files for a given year `time` 
and a survey of type `survey`, simply run:
	
	%let ftyp=;
	%silc_db_locate(&survey, &time, _ftyp_=ftyp);
3. Note that from the output path and dataset, you can easily reconstruct the full path(s) 
(directory name + dataset name + extension) of the original SAS files, _e.g._ for given `survey, 
db, time` and `geo`: 

	%let ds=;
	%let path=;
	%silc_db_locate(survey, db, time, geo=geo, _ds_=ds, _path_=path);
	%let fullpath=%list_append(&path, &ds, zip=%quote(/), rep=%quote( ));
	%let fullpath=%list_append(&fullpath, %list_ones(%list_length(&fullpath), item=sas7bdat), 
	                              zip=%quote(.), rep=%quote( - ));
	
### See also
[%silcx_ds_extract](@ref sas_silcx_ds_extract),
[%_transmissionxyear](@ref cfg_transmissionxyear).
