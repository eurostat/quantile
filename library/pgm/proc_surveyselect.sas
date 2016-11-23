/** 
## proc_surveyselect {#sas_proc_surveyselect}
Alternative sampling of a given dataset with same purpose as `PROC SURVEYSELECT` but a machine
independent implementation. 

	%proc_surveyselect(idsn, odsn, method, sampsize=, rep=, strata=, seed=0, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : a reference input dataset;
* `method` : sampling method; only `SRS` (_i.e._ simple random sampling) and `URS` (_i.e._ unrestricted 
	random sampling, with replacement) are currently implemented;
* `sampsize, rep, seed, strata` : (_option_) same arguments as in `PROC SURVEYSELECT`; default:
	1, 1 (no repetition), 0 and '' respectively;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` is used.

### Returns
`odsn` : name of the output table where the sampled data (of size `sampsize`, see above) will be stored. 

### Examples
Run macro `%%_example_proc_surveyselect` for examples.

### Notes
1. The current version of SAS (9.2 TS Level 2M3) on Solaris machines does not ensure the same output as 
SAS 9.3 and upper for the `PROC SURVEYSELECT`. The issue has been documented [here](http://support.sas.com/kb/53525). This macro provides with an alternative 
approach/algorithm that circumvents this problem for SRS and URS methods. In practice it enables the user 
to produce the same output whatever the SAS version used (see note 4 below). When running on different SAS versions, 
the sampled outputs generated from identical datasets with the same seed will also be identical.
2. In short, this is somehow equivalent to:

        PROC SURVEYSELECT DATA=&ilib..&dsn OUT=&olib..&odsn 
			METHOD = &method rep = &rep 
  			SAMPSIZE = &sampsize
  			SEED = &seed
 			ID &var;
	        STRATA &strata ;
		run;
with the parameters defined above. 
3. Following the implementation of PROC SURVEYSELECT, in case of stratified sampling, the algorithm will select by default 1 unit in each stratum. 
In case `sampsize` is set to one given number `*n*`, the algorithm will select `*n*` units in each stratum. 
Finally, in case `sampsize` designates the name of a dataset, this dataset is supposed to provide the stratum sample size in a variable named `_NSIZE_`.
4. The SYS method should also be implemented in a later version. 
5. This approach was implemented by P.BBES.Lamarche (<mailto:pierre.lamarche@ec.europa.eu>).

### Reference
Fan, C.T., Muller, M.E., and Rezucha, I. (1962): ["Development of sampling plans by using sequential (item by item)
selection techniques and digital computers"](http://www.jstor.org/stable/2281647), JASA, 57(298):387-402, DOI: 10.2307/2281647.

### See also
[%ds_sample](@ref sas_ds_sample),
[SURVEYSELECT](https://support.sas.com/documentation/cdl/en/statug/63033/HTML/default/viewer.htm#surveyselect_toc.htm).
*/ /** \cond */

%macro proc_surveyselect(idsn, odsn, method, sampsize=, rep=, seed=, strata=, ilib=WORK, olib=WORK);

	/* list methods implemented in the macro */
	%let available_methods = urs srs ;

	/* various default settings */
 	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
 	%if %macro_isblank(olib) %then 	%let olib=&ilib;

	%if %macro_isblank(seed) = %then %let seed = 0 ;

	/* various checkings */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter, 
			%list_find(%upcase(&available_methods),%upcase(&method)) EQ ,		
			txt=%bquote(!!! Method &method not available - You may use the following keywords: %list_quote(%upcase(&available_methods),mark=_empty_) !!!)) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter, 
		%eval(&sampsize<0) and %macro_isblank(strata),		
		txt=%bquote(!!! You must specify a positive number as a size of the sample !!!)) %then
	%goto exit;

	%if %error_handle(WarningOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0,		
			txt=! Output dataset %upcase(&odsn) already exists !, 
			verb=warn) %then
		%goto warning;
	%warning: /* nothing in fact: just proceed... */

	%if not %macro_isblank(strata) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%var_check(&idsn, &strata, lib=&ilib) EQ 1,		
				txt=!!! Field %upcase(&strata) not found in dataset %upcase(&idsn) !!!) %then
			%goto exit;
		%if %datatyp(&sampsize) EQ CHAR and %error_handle(ErrorInputDataset, 
				%ds_check(&sampsize) EQ 1,		
				txt=!!! Table %upcase(&sampsize) !!!) %then
			%goto exit;
		%if %datatyp(&sampsize) EQ CHAR and %error_handle(ErrorInputDataset, 
				%var_check(&sampsize, &strata) EQ 1,		
				txt=!!! Field %upcase(&strata) not found in dataset %upcase(&sampsize) !!!) %then
			%goto exit;
		%if %datatyp(&sampsize) EQ CHAR and %error_handle(ErrorInputDataset, 
				%var_check(&sampsize, _nsize_) EQ 1,		
				txt=!!! Field %upcase(_nsize_) not found in dataset %upcase(_nsize_) !!!) %then
			%goto exit;
		%global check_alloc ;
		%ds_iscond(&sampsize,_nsize_ >= 0,name_check=check_alloc) ;
		%if %datatyp(&sampsize) EQ CHAR and %error_handle(ErrorInputParameter,
				&check_alloc ne 1,	
				txt=!!! There are some negative values in _NSIZE_ (table &sampsize) !!!) %then
			%goto exit;
	%end;

	/* main computation */

	%local TMP TMP2;
	%let TMP=_TMP;
	%let TMP2=_TMP2;

	%if %macro_isblank(strata) or %datatyp(&sampsize) = NUMERIC %then %do ;
		DATA &TMP;
			SET &ilib..&idsn;
			random_n = ranuni(&seed);
		run;
	%end;
	%else %do ;
		PROC SORT data=&sampsize;
			BY &strata;
		run;
		PROC SORT data=&ilib..&idsn out=&TMP;
			BY &strata;
		run;

		DATA &TMP;
			MERGE &TMP &sampsize;
			BY &strata;
		run;

		DATA &TMP;
			SET &TMP;
			random_n = ranuni(&seed);
		run;
	%end;

	PROC SORT data=&TMP;
		BY 
		%if not %macro_isblank(strata) %then %do;
			&strata 
		%end;
		random_n;
	run;

	PROC SQL;
		CREATE TABLE &TMP AS
		SELECT *, count(*) as n 
		FROM &TMP 
		%if not %macro_isblank(strata) %then %do;
			GROUP BY &strata
		%end ;
		;
	quit;

	DATA &TMP ;
		ATTRIB replicate format=best32.;
		SET &TMP ;
		do replicate = 1 to &rep;
			output;
		end;
	run ;

	PROC SORT data=&TMP;
		BY replicate
		%if not %macro_isblank(strata) %then %do;
			&strata
		%end;
		;
	run;

	DATA &TMP ;
		SET &TMP ;
		BY replicate 
		%if not %macro_isblank(strata) %then %do;
			&strata
		%end;
		;
		RETAIN s_s 0 k 1 ;
		%if %macro_isblank(strata) or %datatyp(&sampsize) = NUMERIC %then %do;
			_nsize_ = &sampsize;
		%end ;
		CALL streaminit(&seed);
		IF first.replicate 
		%if not %macro_isblank(strata) %then %do;
			or first.&strata
		%end ;
		THEN do ;
			s_s = 0 ;
			k = 1 ;
		end ;
		IF _nsize_ > s_s then do;
			%if %upcase(&method) = URS %then %do;
				s = rand('BINOMIAL',1/(n-k+1),_nsize_-s_s) ;
			%end;
			%else %if %upcase(&method) = SRS %then %do ;
			/* Fan et al. (1962) */
				s =  ((_nsize_-s_s)/(n-(k-1)) > ranuni(&seed)) ;
			%end ;
			s_s = s_s + s;
			k+1;
		end;
	run;

	DATA &olib..&odsn;
		SET &TMP;
		WHERE s>0;
	/*run;
	DATA &olib..&odsn;
		SET &olib..&odsn;*/
		DROP s_s _nsize_ k random_n n
		%if &rep = 1 %then %do ;
			replicate 
		%end;
		;
	run;

	%if &method = URS %then %do;
		DATA &olib..&odsn;
			SET &olib..&odsn;
			do k = 1 to s;
				output;
			end;
			DROP s k;
		run;
	%end;
	%else %do ;
		DATA &olib..&odsn;
			SET &olib..&odsn;
			DROP s;
		run;
	%end ;

	%work_clean(&TMP);

	%exit:

%mend proc_surveyselect;


%macro _example_proc_surveyselect;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local odsn s_size v clist;
	%let odsn=_TMP&sysmacroname;

	%let s_size=2;
	%let rep=1;
	%let seed=-1;
	%put;
	%put (i) Perform SRS sampling of a table of 1000 observations, with sampsize=&s_size, rep=&rep and seed=&seed;
	%_dstest1000;
	%proc_surveyselect(_dstest1000, &odsn, SRS, sampsize=&s_size, rep=&rep, seed=&seed);
	%ds_print(&odsn);

	%put;
	%put (ii) Now SRS stratified sampling with the same parameters (except for the size allocation, specified by the table ALLOC_SAMPLE)...;
	%_dstest1001;
	data alloc_sample ;
	do k = 1 to 10 ;
		_nsize_ = abs(round(rannor(545)))+1 ;
		strata = k ;
		output ;
	end ;
	drop k ;
	run ;
	%proc_surveyselect(_dstest1001, &odsn, SRS, sampsize=alloc_sample, rep=&rep, seed=&seed, strata=strata);
	%ds_print(&odsn);


	/* clean */
	%work_clean(odsn);
	%work_clean(_dstest1000);
	%work_clean(_dstest1001);
%mend _example_proc_surveyselect;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_proc_surveyselect;  
*/

/** \endcond */
