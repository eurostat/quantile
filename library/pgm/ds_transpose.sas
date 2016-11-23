/** 
## ds_transpose {#sas_ds_transpose}
Tanspose many variables in a multiple-row-per-subject table to a one-row-per-subject table

	%ds_transpose(idsn, odsn, var=, by=, pivot=, copy=, missing=no, numeric=no, ilib=WORK, olib=WORK, llib=WORK);
  
### Arguments
* `idsn` : name of the input dataset; 	
* `var` : lists of variables to be transposed; 	
* `by` : name of the variable(s) that identifies(y) a subject; 	
* `pivot` : name of the variable from input dataset for which each row value should lead to series
	of variables (one series per variable listed in `var`, above) in output dataset; there should be 
	only one variable named in pivot argument;
* `copy` : (_option_) list of variables that occur repeatedly with each observation for a subject 
	and will be copied to the resulting dataset; default: not taken into account;	
* `missing` : (_option_) boolean flag (`yes/no`) set to keep (`no`) or drop (`yes`) the observations
	that correspond	to a missing value in pivot from the input dataset before transposing; default: 
	`missing=no`;
* `numeric` : (_option_) boolean flag (`yes/no`) set to replace the observed character string value 
  	for variable used as pivot (when it is indeed a string variable) by numbers as suffixes in 
	transposed variable names or not; default: `numeric=no` (_i.e._ character string values observed 
	in pivot variable will be used as suffixes in new variable names); this is relevant only when 
	pivot variable is literal;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ the value of `ilib` will 
	be used;
* `llib` : (_option_) name of the library where value labels are defined (if any variables of interest 
	in the input dataset were categorical/attached value labels); by default: empty, _i.e._ `WORK` is 
	used.

### Returns
* `odsn` : name of the output dataset.

### Examples
We provide here the examples already used in the original code (see note below).

Given the table `dsn` in `WORK`ing library ("example1"):
centre | subjectno | gender |  visit  |   sbp    |     wt
-------|-----------|--------|---------|----------|-----------
	1  |	1	   | female |	A	  |	121.667	 |	75.4
	1  |	1	   | female	| baseline|	120	 	 |	75
	1  |	1	   | female	| week 1  |	125	 	 |	75.5
	1  |	1	   | female	| week 4  |	120	 	 |	75.7
	1  |	2	   | male   |	A	  |	142.5	 |	71.5
	1  |	2	   | male	| baseline|	140	 	 |	70
	1  |	2	   | male	| week 1  |	145	 	 |	73
	2  |	1	   | female |	A	  |	153.333	 |	90.6667
	2  |	1	   | female	| baseline|	155		 |	90
	2  |	1	   | female	| week 1  |	150	 	 |	90.8
	2  |	1	   | female	 |week 4  |	155	 	 |	91.2
then running:

	%ds_transpose(dsn, out, var=sbp wt, by=centre subjectno, pivot=visit);

will set the output table `out` to:
 centre|subjectno|  sbpA |  wtA  |sbpbaseline|wtbaseline|sbpweek_1|wtweek_1|sbpweek_4|wtweek_4
-------|---------|-------|-------|-----------|----------|---------|--------|---------|--------
	1  |	1	 |121.667| 75.4  | 	120	     | 75       |	 125  |  75.5  |   120   |  75.7
 	1  |	2	 |142.5  | 71.5  | 	140	     | 70       |	 145  |  73    |    .    |   . 
	2  |	1	 |153.333|90.6667| 	155	     | 90       |	 150  |  90.8  |   155   |  91.2

and running:

	%ds_transpose(dsn, out, var=sbp wt, by=centre subjectno, pivot=visit, copy=gender);

will set the output table `out` to:
vcentre|subjectno|  sbpA |  wtA  |sbpbaseline|wtbaseline|sbpweek_1|wtweek_1|sbpweek_4|wtweek_4|gender
-------|---------|-------|-------|-----------|----------|---------|--------|---------|--------|------
	1  |	1	 |121.667| 75.4  | 	120	     | 75       |	 125  |  75.5  |   120   |  75.7  |female
 	1  |	2	 |142.5  | 71.5  | 	140	     | 70       |	 145  |  73    |    .    |   .    | male
	2  |	1	 |153.333|90.6667| 	155	     | 90       |	 150  |  90.8  |   155   |  91.2  |female

Run macro `%%_example_ds_transpose` for examples.

### Notes
1. **The macro `%%ds_transpose` is  a wrapper to L. Joseph's original `%%MultiTranspose` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html>.
2. This macro transposes multiple variables in a dataset as if multiple calls to `PROC TRANSPOSE` were 
performed. Indeed, it is useful when data need to be restructured from a multiple-row-per-subject structure 
into a one-row-per-subject structure. While when only one variable needs to be transposed, `PROC TRANSPOSE` 
can perform the task directly, the same operation may be time consuming when two or more variables need to 
be transposed, since it is then necessary to transpose each variable separately and then merge the transposed 
datasets.
3. The following conditions need to be satisfied:
	* a column used as a pivot cannot have any duplicate values for a given series of values found in
	`by` variables,
	* `copy` variables have the same values within each series of `by` values.
4. Use the following options:
	* `numeric=yes` to use numbers as suffixes in transposed variable names rather than characters,
	* `missing=yes` if you'd rather not drop observations where variable defined as pivot has a missing 
	value.

### Reference
Zdeb, M.(2006): ["An introduction to reshaping (TRANSPOSE) and combining (MATCH-MERGE) SAS datasets"](http://www.lexjansen.com/nesug/nesug06/hw/hw09.pdf).

### See also
[PROC TRANSPOSE](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000063661.htm),
[%MultiTranspose](http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html),
[%MAKEWIDE/%MAKELONG](http://www.sascommunity.org/mwiki/images/3/37/Transpose_Macros_MAKEWIDE_and_MAKELONG.sas).
*/ /** \cond */


%macro ds_transpose(idsn
					, odsn
					, var=
					, by=
					, pivot=
					, copy=
					, missing=no
					, numeric=no
					, ilib=
					, olib=
					, llib=
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

    /* IDSN, ODSN, VAR, BY, PIVOT: check that mandatory arguments were filled */
	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(odsn) EQ 1, mac=&_mac,		
			txt=!!! Output file parameter ODSN must be specified !!!) 
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(idsn) EQ 1, mac=&_mac,		
				txt=!!! Input data parameter IDSN must be specified !!!)
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(var) EQ 1, mac=&_mac,		
				txt=!!! Input list VAR of variables to be transposed must be specified !!!)
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(by) EQ 1, mac=&_mac,		
				txt=!!! Clause BY parameters must be specified !!!)
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(pivot) EQ 1, mac=&_mac,		
				txt=!!! Input PIVOT parameter must be specified !!!) %then
		%goto exit;

	/* MISSING, NUMERIC: check/set */
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&missing), type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%bquote(!!! Input Parameter MISSING is a boolean flag yes/no !!!)) 
			or
			%error_handle(ErrorInputParameter, 
				%par_check(%upcase(&numeric), type=CHAR, set=YES NO) NE 0, mac=&_mac,		
				txt=%bquote(!!! Input Parameter NUMERIC is a boolean flag yes/no !!!)) %then
		%goto exit;

    /* IDSN, ILIB: check/set */
	%if %macro_isblank(ilib) %then 		%let ilib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
			txt=%bquote(!!! Input dataset %upcase(&idsn) not found in library %upcase(&ilib) !!!)) %then
		%goto exit;

    /* ODSN, OLIB: check/set */
	%if %macro_isblank(olib) %then 		%let olib=WORK;
	%if %error_handle(WarningOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=%bquote(! Output dataset %upcase(&idsn) already exists in library %upcase(&olib) !), 
			verb=warn) %then
		%goto warning;
	%warning:

    /* LLIB: check/set */
	%if %macro_isblank(llib)	%then 	%let llib=WORK;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

    %local dsCandidateVarnames 
		dsContents 
		dsCopiedVars 
		dsLocalOut 
		dsNewVars 
		dsNewVarsFreq 
		dsPivotLabels 
		dsPivotLabelsHigh 
		dsPivotLabelsLow 
		dsPivotLabelsOther 
		dsPivotObsValues 
		dsRowvarsFreq 
		dsTmp 
		dsTmpOut 
		dsTransposedVars 
		dsXtraVars;

    %local anyfmtHigh 
		anyfmtLow 
		anyfmtOther 
		anymissinglabel 
		anymissingPivotlabel 
		anyrepeatedvarname 
		byfmt 
		bylbl 
		byvar 
		datefmt;
    %local formatl 
		formattedPivot 
		i 
		llabel 
		lmax 
		lPivotlabel 
		lPivotmylabel;
    %local nbyvars 
		ncandidatevars 
		ncopy 
		newlbl 
		newvar 
		newvars 
		nNewvars 
		npivot 
		npivotvalues 
		nvars;
    %local pivotfmt 
		pivotIsDate 
		pivotIsNumeric 
		pivotvalue 
		s 
		tmp 
		tmpvar;
    %local v 
		vars 		
		xnewvars 
		xtravar 
		ynewvars;

    /* PIVOT names the column in the input file whose row values provide the column names in the output 
	* file.
    * there should only be one variable in the PIVOT statement. Also, the column used for the PIVOT 
	* statement cannot have any duplicate values (for a given set of values taken by variables listed 
	* in BY) */

    %let nbyvars    = %list_length(&by);
    %let npivot    = %list_length(&pivot);

    /* first make sure that no duplicate (in variables by * pivot) is found in source data set */
 	%if %error_handle(ErrorOutputParameter, 
			&npivot NE 1, mac=&_mac,		
			txt=!!! Only one variable can be passed through PIVOT parameter !!!) %then
        %goto exit;

    %let dsCandidateVarnames=%str_dsname(candidatevarnames, prefix=_);
    %let ncandidatevars=%sysevalf(&nbyvars+2);

    DATA &dsCandidateVarnames;
        RETAIN found 0;
        LENGTH vname $ 32;
        do i = 1 to &ncandidatevars;
            vname = cats("_", i);
            if vname not in (%list_quote(&by &pivot)) then do;
                if not found then output;
                found = 1;
            end;
        end;
    run;

    PROC SQL noprint;
        SELECT strip(vname) 
		INTO :tmpvar
        FROM &dsCandidateVarnames;
    quit;

    %let dsRowvarsFreq = %str_dsname(rowvarsfreq, prefix=_);

    PROC SQL;
        CREATE TABLE &dsRowvarsFreq as
        SELECT %list_quote(&by &pivot, mark=_EMPTY_), sum(1) as &tmpvar
        FROM &ilib..&idsn
        %if %upcase("&missing")="NO" %then %do;
            WHERE not missing(&pivot)
        %end;
        GROUP %list_quote(&by &pivot, mark=_EMPTY_)
        ;
    quit;

    PROC SQL noprint;
        SELECT max(&tmpvar) 
		INTO :tmp
        FROM &dsRowvarsFreq;
    quit;

    %work_clean(&dsCandidateVarnames, &dsRowvarsFreq);

 	%if %error_handle(ErrorOutputParameter, 
			&tmp GT 1, mac=&_mac,		
			txt=!!! Duplicates were found in data IDSN in variables BY * PIVOT !!!) %then
		%goto exit;

    /* now make sure that no duplicate (in by * copy) is found in source dataset */

    %let ncopy = %list_length(&copy);

    %if &ncopy %then %do;
        %let dsCopiedVars = %str_dsname(copiedvars);

        PROC SQL;
            CREATE TABLE &dsCopiedVars AS
            SELECT distinct %list_quote(&by &copy, mark=_EMPTY_)
            FROM &ilib..&idsn;
        quit;

        PROC SQL;
            CREATE TABLE &dsRowvarsFreq AS
            SELECT %list_quote(&by, mark=_EMPTY_), sum(1) AS &tmpvar
            FROM &dsCopiedVars
            GROUP %list_quote(&by, mark=_EMPTY_);
        quit;

        PROC SQL noprint;
            SELECT max(&tmpvar) 
			INTO :tmp
            FROM &dsRowvarsFreq;
        quit;
        %work_clean(&dsRowvarsFreq);

	 	%if %error_handle(ErrorOutputParameter, 
				&tmp GT 1, mac=&_mac,		
				txt=!!! Some COPY variables are not uniquely defined for some output data rows (defined by BY) !!!) %then %do;
			%work_clean(&dsCopiedVars);
			%goto exit;
    	%end;
    %end;

    /* create ODSN, just to make sure it exists and its name is not recycled */
    DATA &olib..&odsn; stop; 
	run;

    %let dsContents = %str_dsname(contents, prefix=_);
    PROC CONTENTS data=&ilib..&idsn noprint out=&dsContents (keep=name label type format formatl); 
	run;

    %let dsTmp = %str_dsname(tmp, prefix=_);

    PROC SQL noprint;
		SELECT compress(ifc(substr(format,1,1) eq "$", substr(format,2), format)), 
			type eq 1, 
			formatl,
    		format in ("DATE", "DDMMYY", "DDMMYYB", "DDMMYYC", "DDMMYYD", "DDMMYYN", "DDMMYYP", "DDMMYYS", "EURDFDE", "EURDFMY", "EURDFDMY", "EURDFWKX",
    				"JULIAN", "MINGUO", "MMDDYY", "MMDDYYB", "MMDDYYC", "MMDDYYD", "MMDDYYN", "MMDDYYP", "MMDDYYS", "MMYY", "MMYYC", "MMYYD", "MMYYN", "MMYYP", "MMYYS",
                	"MONYY", "NENGO", "PDJULG", "PDJULI", "WEEKDATE", "WORDDATE", "WORDDATX",
                    "YYMM", "YYMMC", "YYMMDD", "YYMMP", "YYMMS", "YYMMN", "YYMMDD", "YYMON", "YYQ", "YYQC", "YYQD", "YYQP", "YYQSYYQN", "YYQR", "YYQRC", "YYQRD", "YYQRP", "YYQRS")
        INTO :pivotfmt, :pivotIsNumeric, :formatl, :pivotIsDate
        FROM &dsContents
        WHERE upcase(name) eq upcase("&pivot");
    quit;

    %if &pivotIsDate %then %do;
        %if &formatl eq 0 %then 	%let datefmt=&pivotfmt;
        %else 						%let datefmt=%sysfunc(compress(&pivotfmt.&formatl));
    %end;

    /* Pivot values */;

    %let dsPivotObsValues = %str_dsname(obspivots, prefix=_); 
    PROC SQL;
        CREATE TABLE &dsPivotObsValues AS
        SELECT distinct(&pivot) as PivotValue
        FROM &ilib..&idsn
        %if %upcase("&missing")="NO" %then %do;
            WHERE not missing(&pivot)
        %end;
        ORDER &pivot;
    quit;

    DATA &dsPivotObsValues;
        SET &dsPivotObsValues;
        PivotIndex = _N_;
    run;

    PROC SQL noprint;
        SELECT N(PivotIndex) 
		INTO :npivotvalues
        FROM &dsPivotObsValues;
    quit;

    /* var to transpose */
    %let nvar = %list_length(&var);

    %let dsTransposedVars = %str_dsname(transposedvars, prefix=_);
    DATA &dsTransposedVars;
        LENGTH name $32;
        %do i = 1 %to &nvar;
            %let v = %scan(&var, &i);
            name = "&v";
            output;
        %end;
    run;

    %let dsNewVars = %str_dsname(newvars, prefix=_);

    PROC SQL;
		CREATE TABLE &dsNewVars AS
        SELECT v.name, 
			upcase(v.name) as ucname, 
			s.PivotValue, 
			s.PivotIndex,
       		%if &pivotIsNumeric %then %do;
             	CASE
                    WHEN s.PivotValue eq . THEN    cats(v.name, "00")
                    %if &pivotIsDate %then %do;
                        ELSE cats(v.name, compress(put(s.PivotValue, &datefmt..)))
                    %end;
                    %else %do;
                        ELSE cats(v.name, s.PivotValue)
                    %end;
                END as NewVar length=200
			%end;
	        %else %if %upcase("&numeric")="YES" %then %do;
				cats(v.name, s.PivotIndex) as NewVar length=200
            %end;
       		%else %do;
  				tranwrd(compbl(cats(v.name, s.PivotValue)), " ", "_") as NewVar length=200
          	%end;
	FROM &dsTransposedVars as v, &dsPivotObsValues as s;
    quit;

    DATA &dsNewVars (drop=j);
        SET &dsNewVars;
        j = notalnum(NewVar);
        do while(j gt 0 and j le length(NewVar));
            if        j gt 1        then NewVar = substr(NewVar, 1, j-1) || "_" || substr(NewVar, j+1);
            else    if j eq 1    then NewVar = "_" || substr(NewVar, 2);
            j = notalnum(NewVar, j+1);
        end;
        ucnewvar = upcase(NewVar);
    run;

    %let dsXtraVars = %str_dsname(xtravars, prefix=_);
    DATA &dsXtraVars;
        LENGTH ucnewvar $ 200;
        %do i = 1 %to &nbyvars;
            %let xtravar = %scan(&by, &i);
            ucnewvar = strip(upcase("&xtravar"));
            output;
        %end;
        %do i = 1 %to &ncopy;
            %let xtravar = %scan(&copy, &i);
            ucnewvar = strip(upcase("&xtravar"));
            output;
        %end;
    run;

    %let dsNewVarsFreq = %str_dsname(newvarsfreq, prefix=_);
    PROC SQL;
        CREATE TABLE &dsNewVarsFreq AS
        SELECT a.ucnewvar, 
			N(a.ucnewvar) as f
        FROM
            (
                SELECT ucnewvar FROM &dsNewVars
                OUTER UNION corresponding
                SELECT ucnewvar FROM &dsXtraVars
            ) as a
        GROUP a.ucnewvar;
    quit;

	%work_clean(&dsXtraVars);

	PROC SQL noprint;
        SELECT ucnewvar, 
			N(ucnewvar) gt 0 
		INTO :multipdefnvars separated by ", ", :anyrepeatedvarname
        FROM &dsNewVarsFreq
        WHERE f gt 1;
    quit;

	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(anyrepeatedvarname) NE 1 and 0 NE &anyrepeatedvarname, mac=&_mac,		
			txt=%bquote(!!! Given the variables to transpose and the values taken by PIVOT, 
				some variables created in transposed output dataset would have ambiguous meanings -
				Rename some of the variables to transpose in order to avoid these ambiguities !!!)) %then %do;
		/* delete &olib..&odsn /* %work_clean(&out); */
		%goto clean;
    %end;

    /* pivot fmt values */;

    %let dsPivotLabels = %str_dsname(pivotlabels, prefix=_);
    %let formattedPivot = 0;

    %if %length(&pivotfmt) %then %do;
        %if &pivotIsDate %then %do;
            %let formattedPivot = 1;
            %let anyfmtHigh = 0;
            %let anyfmtLow = 0;
            %let anyfmtOther = 0;

            PROC SQL;
                CREATE TABLE &dsPivotLabels AS
                SELECT PivotValue as start, 
					PivotValue as end, 
					compress(put(PivotValue, &datefmt..)) as Label
                FROM &dsPivotObsValues;
            quit;
        %end;
        %else %if %upcase("&llib") eq "WORK" or %sysfunc(exist(&llib..formats)) %then %do;
            %let formattedPivot = 1;
            PROC FORMAT library=&llib cntlout=&dsTmp; 
			run;

            DATA &dsTmp;
                SET &dsTmp;
                if upcase(fmtname) ne upcase("&pivotfmt") then delete;
                High = 0;
                Low = 0;
                Other = 0;
                if            upcase(HLO) eq "L"    then do;
                    start    = "";
                    Low = 1;
                end;
                else if    upcase(HLO) eq "H"    then do;
                    end    = "";
                    High = 1;
                end;
                else if    upcase(HLO) eq "O"    then do;
                    start = "";
                    end    = "";
                    Other = 1;
                end;
            run;

            PROC SQL;
				CREATE TABLE &dsPivotLabels AS
				SELECT 
					%if &pivotIsNumeric %then %do;
						input(start, best32.) as start, 
						input(end, best32.) as end, 
			  		%end;
			     	%else %do;
                     	start, 
						end, 
           			%end;
					Label, 
					High, 
					Low, 
					Other
            	FROM &dsTmp;
            quit;

            PROC SQL noprint;
                SELECT max(High), 
					max(Low), 
					max(Other) 
					INTO :anyfmtHigh, :anyfmtLow, :anyfmtOther
                FROM &dsPivotLabels;
            quit;

            %if &anyfmtHigh %then %do;
                %let dsPivotLabelsHigh = %str_dsname(pivotlabelshigh, prefix=_);
                PROC SQL;
                    CREATE TABLE &dsPivotLabelsHigh AS
                    SELECT start, Label
                    FROM &dsPivotLabels
                    WHERE High eq 1;
                    DELETE FROM &dsPivotLabels 
					WHERE High eq 1;
                quit;
            %end;

            %if &anyfmtLow %then %do;
                %let dsPivotLabelsLow = %str_dsname(pivotlabelslow, prefix=_);
                PROC SQL;
                    CREATE TABLE &dsPivotLabelsLow AS
                    SELECT end, Label
                    FROM &dsPivotLabels
                    WHERE Low eq 1;
                    DELETE FROM &dsPivotLabels 
					WHERE Low eq 1;
                quit;
            %end;

            %if &anyfmtOther %then %do;
                %let dsPivotLabelsOther = %str_dsname(pivotlabelsother, prefix=_);
                PROC SQL;
                    CREATE TABLE &dsPivotLabelsOther AS
                    SELECT Label
                    FROM &dsPivotLabels
                    WHERE Other eq 1;
                    DELETE FROM &dsPivotLabels 
					WHERE Other eq 1;
                quit;
            %end;

            %work_clean(&dsTmp);
        %end;
    %end;
    %else %do;
        PROC SQL;
            CREATE TABLE &dsPivotLabels AS
            SELECT PivotValue as start, 
				PivotValue as end, 
				"" as Label
            FROM &dsPivotObsValues;
        quit;
    %end;

   /* transpose input dataset, one pivot-value at a time */

    %let dsLocalOut= %str_dsname(localout, prefix=_);
    %let dsTmpOut= %str_dsname(tmpout, prefix=_);

    %do s = 1 %to &npivotvalues;
        PROC SQL noprint;
            SELECT name, 
				NewVar, 
				NewVar 
			INTO :vars separated by ' ', :newvars separated by ' ', :ynewvars separated by ", y."
            FROM &dsNewVars
            WHERE PivotIndex eq &s;
        quit;
        
        PROC SQL;
            CREATE TABLE &dsTmp AS
            SELECT %str_varlist(&by, ds=d)
	            %do i = 1 %to &nvar;
	                %let v = %scan(&vars, &i);
	                %let newvar = %scan(&newvars, &i);
	                , d.&v as &newvar
	            %end;
            FROM &ilib..&idsn as d, &dsPivotObsValues as s
            WHERE d.&pivot eq s.PivotValue and s.PivotIndex eq &s;
        quit;

        %if &s eq 1 %then %do;
            %ds_rename(&dsTmp, &dsLocalOut);
            %let xnewvars=&newvars;
        %end;
        %else %do;
            PROC SQL;
                CREATE TABLE &dsTmpOut as
                SELECT
                    %do i = 1 %to &nbyvars;
                        %let byvar = %scan(&by, &i);
                        coalesce(x.&byvar, y.&byvar) as &byvar,
                    %end;
                    %str_varlist(&xnewvars, ds=x), y.&ynewvars
                FROM &dsLocalOut as x
                FULL JOIN &dsTmp as y
                ON
                    %do i = 1 %to &nbyvars;
                        %let byvar = %scan(&by, &i);
                        %if &i gt 1 %then %do;
                            and
                        %end;
                        x.&byvar eq y.&byvar
                    %end;
                    ;
            quit;
            %work_clean(&dsLocalOut);
       		%ds_rename(&dsTmpOut, &dsLocalOut);
            %let xnewvars=&xnewvars &newvars;
        %end;
    %end;


    %if &ncopy eq 0 %then %do;
    	/*%work_clean(&out);
     	%ds_rename(&dsLocalOut, &out);*/
		DATA &olib..&odsn;
			SET &dsLocalOut;
		run;
    %end;
    %else %do;
        PROC SQL;
            CREATE TABLE &olib..&odsn as
            SELECT t.*, 
				%str_varlist(&copy, ds=c)
            FROM &dsLocalOut as t, &dsCopiedVars as c
            WHERE
            %do i = 1 %to &nbyvars;
                %let byvar = %scan(&by, &i);
                %if &i gt 1 %then %do;
                    and
                %end;
                t.&byvar eq c.&byvar
            %end;
            ;
        quit;
        %work_clean(&dsCopiedVars);
    %end;
    %work_clean(&dsLocalOut);
    
    /* Get variable labels */;

    PROC SQL;
        CREATE TABLE &dsTmp as
        SELECT t.*, 
			c.label
        FROM &dsTransposedVars as t, &dsContents as c
        WHERE upcase(t.name) eq upcase(c.name);
    quit;

    PROC SQL noprint;
        SELECT max(length(strip(label))), 
			max(length(strip(name))), 
			max(missing(label)) 
		INTO :llabel, :lmax, :anymissinglabel
        FROM &dsTmp;
    quit;

    %if &anymissinglabel and &lmax gt &llabel %then 	%let llabel = &lmax;

    PROC SQL;
        CREATE TABLE &dsTransposedVars as
        SELECT *, 
			coalesce(strip(label), 
			strip(name)) as newvarLabel
        FROM &dsTmp;
    quit;
    %work_clean(&dsTmp);

    /* if pivot is a formatted variable, get the formats for each of its values, else define a label 
	* as "pivot = Value" */

    %if &formattedPivot %then %do;
        PROC SQL;
            CREATE TABLE &dsTmp as
            SELECT s.PivotValue, 
				s.PivotIndex, 
				l.Label as PivotLabel
            FROM &dsPivotObsValues as s
            LEFT JOIN &dsPivotLabels as l
            ON (missing(s.PivotValue) and s.PivotValue eq l.start)
                or (not missing(s.PivotValue) and s.PivotValue ge l.start and s.PivotValue le l.end);
        quit;

        %if &anyfmtHigh %then %do;
       		%work_clean(&dsPivotObsValues);
            %ds_rename(&dsTmp, &dsPivotObsValues);
            PROC SQL;
                CREATE TABLE &dsTmp AS
                SELECT s.PivotValue, s.PivotIndex, coalesce(s.Label, x.Label) as PivotLabel
                FROM &dsPivotObsValues as s
                LEFT JOIN &dsPivotLabelsHigh as x
                ON s.PivotValue ge x.start;
            quit;
            %work_clean(&dsPivotLabelsHigh);
        %end;

        %if &anyfmtLow %then %do;
       		%work_clean(&dsPivotObsValues);
         	%ds_rename(&dsTmp, &dsPivotObsValues);
            PROC SQL;
                CREATE TABLE &dsTmp AS
                SELECT s.PivotValue, s.PivotIndex, coalesce(s.Label, x.Label) as PivotLabel
                FROM &dsPivotObsValues as s
                LEFT JOIN &dsPivotLabelsLow as x
                ON s.PivotValue le x.end;
            quit;
            %work_clean(&dsPivotLabelsLow);
        %end;

        %if &anyfmtOther %then %do;
          	%work_clean(&dsPivotObsValues);
         	%ds_rename(&dsTmp, &dsPivotObsValues);
            PROC SQL;
                CREATE TABLE &dsTmp AS
                SELECT s.PivotValue, 
					s.PivotIndex, 
					coalesce(s.Label, x.Label) as PivotLabel
                FROM &dsPivotObsValues as s, &dsPivotLabelsOther as x;
            quit;
            %work_clean(&dsPivotLabelsOther);
        %end;
    %end;
    %else %do;
        PROC SQL;
            CREATE TABLE &dsTmp as
            SELECT PivotValue, 
				PivotIndex, 
				"" as PivotLabel
            FROM &dsPivotObsValues;
        quit;
    %end;
	%work_clean(&dsPivotObsValues);
    %ds_rename(&dsTmp, &dsPivotObsValues);

    PROC SQL noprint;
        SELECT N(PivotIndex) gt 0 
		INTO :anymissingpivotlabel
        FROM &dsPivotObsValues
        WHERE missing(PivotLabel);
    quit;

    %if &anymissingpivotlabel %then %do;
        PROC SQL noprint;
            SELECT max(length(PivotLabel)) 
			INTO :lpivotlabel
            FROM &dsPivotObsValues;
        quit;

        PROC SQL noprint;
        	SELECT 
	       		%if &pivotIsNumeric %then %do;
					max(length(strip(put(PivotValue, best32.)))) 
		        %end;
		        %else %do;
					max(length(PivotValue)) 
        		%end;
			INTO :lpivotmylabel
        	FROM &dsPivotObsValues;
        quit;

        %let lpivotmylabel = %sysevalf(3+&lpivotmylabel+%length(&pivot));
        %if &lpivotmylabel gt &lpivotlabel %then %let lpivotlabel = &lpivotmylabel;

		PROC SQL;
       		CREATE TABLE &dsTmp as
            SELECT PivotValue, 
				PivotIndex, 
        		%if &pivotIsNumeric %then %do;
					coalesce(PivotLabel, catx(" = ", strip("&pivot"), strip(put(PivotValue, best32.)))) as PivotLabel length=&lpivotlabel
          		%end;
        		%else %do;
  					coalesce(PivotLabel, catx(" = ", strip("&pivot"), strip(PivotValue))) as PivotLabel length=&lpivotlabel
         		%end;
     		FROM &dsPivotObsValues;
       	quit;

		%work_clean(&dsPivotObsValues);
        %ds_rename(&dsTmp, &dsPivotObsValues);
    %end;

    * Give new labels to new (transposed) variables;

    PROC SQL;
        CREATE TABLE &dsTmp as
        SELECT n.newvar, 
			t.newvarlabel, 
			s.PivotLabel
        FROM &dsNewVars as n, &dsTransposedVars as t, &dsPivotObsValues as s
        WHERE n.name eq t.name and n.PivotIndex eq s.PivotIndex;
    quit;
	%work_clean(&dsNewVars);
    %ds_rename(&dsTmp, &dsNewVars);

    PROC SQL noprint;
        SELECT NewVar, 
			N(NewVar) 
		INTO :newvars separated by ' ', :nNewvars
        FROM &dsNewVars;
    quit;

    %do i = 1 %to &nNewvars;
        %let newvar = %scan(&newvars, &i);

        PROC SQL noprint;
            SELECT catx(":: ", tranwrd(newvarLabel, '"', '""'), tranwrd(PivotLabel, '"', '""')) 
			INTO :newlbl
            FROM &dsNewVars
            WHERE NewVar eq "&newvar";
        quit;

        PROC DATASETS lib=&olib nolist;
            MODIFY &odsn;
            LABEL &newvar = "&newlbl";
        quit;
    %end;

    /* put back format on by variables */

    %do i = 1 %to &nbyvars;
        %let byvar = %scan(&by, &i);
        %let byfmt=;
        %let bylbl=;
        PROC SQL noprint;
            SELECT
                ifc(anyalnum(format) or formatl gt 0, cats(format, ifc(formatl gt 0, strip(put(formatl, 4.)), ""), "."), ""),
                tranwrd(label, '"', '""')
            INTO :byfmt, :bylbl
            FROM &dsContents
            WHERE lowcase(name) eq lowcase("&byvar");
        quit;

        %if %length(&byfmt) or %length(&bylbl) %then %do;
			PROC DATASETS lib=&olib nolist;
                MODIFY &odsn;
                %if %length(&bylbl) %then %do;
                    LABEL &byvar = "&bylbl";
                %end;
                %if %length(&byfmt) %then %do;
                    FORMAT &byvar &byfmt;
                %end;
            quit;
        %end;
    %end;

	%work_clean(&dsPivotLabels)

    %clean:
    %work_clean(&dsContents, &dsNewVars, &dsNewVarsFreq, &dsPivotObsValues, &dsTransposedVars);

    %exit:
%mend ds_transpose;


%macro _example_ds_transpose;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn out;
	%let dsn=_TMP&sysmacroname;
	%let out=_OUT&sysmacroname;

	DATA &dsn.1;
	    centre=1; subjectno=1; gender="female"; visit="A       "; sbp=121.667; wt=75.4; output;
		centre=1; subjectno=1; gender="female"; visit="baseline"; sbp=120; 	   wt=75; output;
		centre=1; subjectno=1; gender="female"; visit="week 1";   sbp=125;     wt=75.5; output;
	   	centre=1; subjectno=1; gender="female"; visit="week 4";   sbp=120;     wt=75.7; output;
	    centre=1; subjectno=2; gender="male"; 	visit="A";        sbp=142.500; wt=71.5; output;
	    centre=1; subjectno=2; gender="male"; 	visit="baseline"; sbp=140;     wt=70; output;
	    centre=1; subjectno=2; gender="male"; 	visit="week 1";   sbp=145;     wt=73; output;
	    centre=2; subjectno=1; gender="female"; visit="A";        sbp=153.333; wt=90.6667; output;
	    centre=2; subjectno=1; gender="female"; visit="baseline"; sbp=155;     wt=90; output;
	    centre=2; subjectno=1; gender="female"; visit="week 1";   sbp=150;     wt=90.8; output;
	    centre=2; subjectno=1; gender="female"; visit="week 4";   sbp=155;     wt=91.2; output;
	run;
	%ds_print(&dsn.1);

	/* original: %MultiTranspose(data=&dsn.1, out=out1, vars=sbp wt, by=centre subjectno, pivot=visit); */
	%ds_transpose(&dsn.1, &out.1, var=sbp wt, by=centre subjectno, pivot=visit);
	%ds_print(&out.1);

	/* original: %MultiTranspose(data=&dsn.1, out=out1_1, vars=sbp wt, by=centre subjectno, pivot=visit, dropMissingPivot=0); */ 
	%ds_transpose(&dsn.1, &out.2, var=sbp wt, by=centre subjectno, pivot=visit, missing=yes);
	%ds_print(&out.2);

	/* original: %MultiTranspose(data=&dsn.1, out=out1_2, vars=sbp wt, by=centre subjectno, pivot=visit, copy=gender); */ 
	%ds_transpose(&dsn.1, &out.3, var=sbp wt, by=centre subjectno, pivot=visit, copy=gender);
	%ds_print(&out.3);

	%work_clean(&dsn.1, &out.1, &out.2, &out.3);
%mend _example_ds_transpose;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_transpose;
*/

/** \endcond */
