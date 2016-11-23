/** \cond */
/** 
## proc_format {#sas_proc_format}

### References
1. Shoemaker, J.N. (2002): ["PROC FORMAT in action"](http://www2.sas.com/proceedings/sugi27/p056-27.pdf).
2. Bilenas, J.V. (2005): ["The power of PROC FORMAT; updated for SAS9"](http://www.lexjansen.com/nesug/nesug05/pm/pm6.pdf).
3. Li, S. (2011): ["Some useful techniques of PROC FORMAT"](http://www.pharmasug.org/proceedings/2011/CC/PharmaSUG-2011-CC19.pdf).
3. ["Creating and using formats and format libraries in SAS"](http://www.ats.ucla.edu/stat/sas/library/formats.htm).

### See also
[%label_zip](@ref sas_label_zip), [PROC FORMAT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473464.htm).
*/ /** \cond */


%macro proc_format(var)
	%let _mac=&sysmacroname;

	/* open the &var catalog */
	/* write something like
	PROC FORMAT library=catalog.formats_&var;	
	*/

	%local ifn ds;
	%local FORMAT_LABELS LABELNAME SEP;
	%local formats lformats labels llabels;
	%local start end sexcl eexcl;
		
	%let SEP=%str( );

	%let ds=;
	%if %symexist(G_PING_FORMAT_LABELS) %then 	%let FORMAT_LABELS=&G_PING_FORMAT_LABELS;
	%else 									%let FORMAT_LABELS=FORMAT_LABELS;

	%if %symexist(G_PING_LABELNAME) %then 	%let LABELNAME=&G_PING_LABELNAME;
	%else 								%let LABELNAME=LABELNAME;

	%let dsn=TMP%upcase(&_mac);
	%let ifn=%upcase(&var)&FORMAT_LABELS;

	%file_import(&ifn, &type, _ds_=&dsn, idir=&G_PING_LIBDATA, olib=WORK);

	/* retrieve all the formats' names */
	%ds_contents(&dsn, _varlst_=formats, lib=WORK);
	%let formats=%list_difference(&formats, &LABELNAME START END SEXCL EEXCL TYPE);
	%let lformats=%list_length(&formats, sep=&SEP);

	/* retrieve all the labels' names */
	%var_to_list(&dsn, &LABELNAME, _varlst_=labels, distinct=yes);
	%let llabels=%list_length(&labels, sep=&SEP);

	/* loop over labels */
	%local i label;
	%do i=1 %to &llabels;
		%let label = %list_index(&labels, &i, sep=&SEP);
		%var_to_list(&dsn, START, _varlst_=start);
		%var_to_list(&dsn, END, _varlst_=end);
		%var_to_list(&dsn, SEXCL, _varlst_=sexcl);
		%var_to_list(&dsn, EEXCL, _varlst_=eexcl);
		%let cat_&label=%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl);
		%work_clean(TMP);
	%end;

	/* loop over formats */
	%local k format;
	%do k=1 %to &lformats;
		%let format = %list_index(&formats, &k, sep=&SEP);
		/* write into the file something like 
			%put VALUE &format (multilabel)
		%/
		/* retrieve all labels used by format */
		%let where=%quote(&label=1);
		%ds_select(&dsn, &LABELNAME, TMP, where=&where);
		%var_to_list(&dsn, &LABELNAME, _varlst_=labels, distinct=yes);
		%let llabels=%list_length(&labels, sep=&SEP);
		/* insert cat_&label when used */
		%do i=1 %to &llabels;
			%let label = %list_index(&labels, &i, sep=&SEP);
			/* write into the file something like 
				%put cat_&label = "&label";
			look into datacheck o write into PROC FORMAT ... */
		%end;
		/* write into the file something like 
		%put %str(;);
		*/
	%end;

	/* %put run;
	close the &var catalog */


	%work_clean(&dsn);
	%exit:
%mend proc_format;

%macro _example_proc_format;
%mend _example_proc_format;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_proc_format; 
*/

/** \endcond */
