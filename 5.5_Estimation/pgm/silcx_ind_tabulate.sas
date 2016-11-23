/** 
## silcx_ind_tabulate {#sas_silcx_ind_tabulate}
*/ /** \cond */

%macro silcx_ind_tabulate(idsn
						, var
						, dimensions
						, yyyy
						, odsn
						, cond=
						, labels=
						, iformats=
						, cformats=
						, iflag=
						, mflag=
						, stats=
						, ilib=
						, olib=
					);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(ilib) %then %let ilib=WORK;
	%if %macro_isblank(olib) %then %let olib=&ilib;

	%local 
		v_GEo			/* name of geo variable */
		v_TIME			/* ibid, time */
		v_WEIGHT;		/* ibid, weight */
		v_UNIT			/* ibid, unit */
		v_VALUE			/* ibid, value */
		v_UNREL			/* ibid, unrel */
		v_N				/* ibid, n */
		v_NTOT			/* ibid, ntot */
		v_TOTWGH		/* ibid, totwgh */
		v_IFLAG;		/* ibid, iflag */

	/* retrieve global setting whenever it exitsts */
	%if %symexist(G_PING_VAR_GEO) %then 		%let v_GEO=&G_PING_VAR_GEO;
	%else										%let v_GEO=geo;
	%if %symexist(G_PING_VAR_TIME) %then 		%let v_TIME=&G_PING_VAR_TIME;
	%else										%let v_TIME=time;
	%if %symexist(G_PING_VAR_WEIGHT) %then 		%let v_WEIGHT=&G_PING_VAR_WEIGHT;
	%else										%let v_WEIGHT=weight;
	%if %symexist(G_PING_VAR_GEO) %then 		%let v_GEO=&G_PING_VAR_GEO;
	%else										%let v_GEO=geo;
	%if %symexist(G_PING_VAR_TIME) %then 		%let v_TIME=&G_PING_VAR_TIME;
	%else										%let v_TIME=time;
	%if %symexist(G_PING_VAR_UNIT) %then 		%let v_UNIT=&G_PING_VAR_UNIT;
	%else										%let v_UNIT=unit;
	%if %symexist(G_PING_VAR_VALUE) %then 		%let v_VALUE=&G_PING_VAR_VALUE;
	%else										%let v_VALUE=ivalue;
	%if %symexist(G_PING_VAR_UNREL) %then 		%let v_UNREL=&G_PING_VAR_UNREL;
	%else										%let v_UNREL=unrel;
	%if %symexist(G_PING_VAR_N) %then 			%let v_N=&G_PING_VAR_N;
	%else										%let v_N=n;
	%if %symexist(G_PING_VAR_NTOT) %then 		%let v_NTOT=&G_PING_VAR_NTOT;
	%else										%let v_NTOT=ntot;
	%if %symexist(G_PING_VAR_TOTWGH) %then 		%let v_TOTWGH=&G_PING_VAR_TOTWGH;
	%else										%let v_TOTWGH=totwgh;
	%if %symexist(G_PING_VAR_IFLAG) %then 		%let v_IFLAG=&G_PING_VAR_IFLAG;
	%else										%let v_IFLAG=iflag;

	%if &stats= %then 	%let stats='RowPctSum' 'N' 'Sum'; 
	/* note: if a variable name (class or analysis) and a statistic name are the
	* same, then the statistic name should be enclosed in single quotation marks */
	%if &mflag= %then 	%let mflag=NO;
	%if &iflag= %then 	%let iflag=;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* locally used variables */
	%local _i			/* loop increment */
		weight			/* weight variable depending on the input variable */
		_tmp			/* name of the temporary dataset */
		ndim			/* number of dimensions */
		dim				/* single dimension */
		ifmt			/* number used to index the format category */
		corder			/* index order (of the form 1011) used to retrieve statistics */
		_oldfmtpath		/* old path of fmtsearch */
		per_dimensions;	/* formatted crossed dimensions */
	%let _tmp=TMP_&_mac;

	/* retrieve the number of dimensions */
	%let ndim=%sysfunc(countw(&dimensions)); /* %list_length(&dimensions) */

	/* set default labels */
	%if %macro_isblank(labels)  %then %do;
		%let labels=&dimensions;
	%end;

	/* define formats used by the indicator */
	%if %macro_isblank(formats) %then %do;
	/* if it does not exist, define it on the fly */
		%*let iformats=;
		%do _i=1 %to &ndim;
			%let iformats=&iformats 1;
		%end;
	%end;
			
	%if %macro_isblank(cformats) %then %do;
		%if %symexist(G_PING_CATFMT) %then 		%let cformats=&G_PING_CATFMT;
		%else 									%let cformats=CATFMT; /* WORK */
	%end;

	/* retrieve the format from current fmtsearch */
	%let _oldfmtpath = %upcase(%cmpres(%sysfunc(getoption(fmtsearch))));
	/* load the formats from a catalog of existing formats: either in the config library */
	option nofmterr fmtsearch=(
		%do _i=1 %to &ndim;
			%let dim=%scan(&dimensions, &_i);
			&cformats..formats_&dim
		%end;
		) nodate;   

	/* missing and unreliable*/
	%if %upcase(&mflag)=YES %then %do;
		PROC SQL ;  /* checkkkkkkkkkkkkkkkkkkkkkkkkk */
			CREATE TABLE nfilled AS 
				SELECT DISTINCT &v_GEO, 
					(N(RB030)) AS N1 
				FROM &ilib..&idsn 
				WHERE &var._F  in (1,-2,-3) 
				GROUP BY &v_GEO;
			CREATE TABLE nmissing AS 
				SELECT DISTINCT &v_GEO, 
					(N(RB030)) AS N_1 
			    FROM &ilib..&idsn 
				WHERE &vari._F = -1 
				GROUP BY &v_GEO;
			CREATE TABLE missunrel AS 
				SELECT nfilled.&v_GEO, 
					(100/(N1+N_1)*N_1) AS pcmiss
				FROM nfilled 
				LEFT JOIN nmissing ON (nfilled.&v_GEO = nmissing.&v_GEO);
		quit;  
	%end;

	/* define the list of "per variables", i.e. if dimensions=AGE RB090 HT1 QITILE,
	* then we will have per_dimensions=AGE*RB090*HT1*QITILE 
	* this is useful for the following PROC TABULATE */
	%let per_dimensions=%list_quote(&dimensions, mark=_empty_, rep=%str(*));;

	/* perform the tabulate operation
	* define at the same time the class order used to retrieve the correct statistics based on 
	* PctSum. corder (of the form 011, 1010, ...) depends on the order the classes used as rows/cols
	* in the table are inserted throughout the TABULATE procedure */
	PROC TABULATE data=&ilib..&idsn out=WORK.&_tmp ; 
		CLASS &v_GEO; 								/* DB020 will be used as row */
		%let corder=1; 								/* 1 for class DB020 row */
		%do _i=1 %to &ndim;
			%let dim=%scan(&dimensions, &_i);
			%let ifmt=%scan(&iformats, &_i);
			format &dim _fmt&ifmt._&dim._.;
			CLASS &dim / MLF ;						/* &dim will be used as row through &per_dimensions */
			%let corder=&corder.1; 					/* 1 for &dim row */
		%end;
		CLASS &var;									/* &var will be used as row */
		%let corder=&corder.0; 						/* 0 for class &var col */
		VAR &v_WEIGHT;
		TABLE &v_GEO * &per_dimensions, &var * &v_WEIGHT  * (&stats) /printmiss;
	run;

	/* run the insertion procedure */
	PROC SQL;
		INSERT INTO &olib..&odsn 
		SELECT *
		FROM
			(SELECT 
				TMP.&v_GEO 													as &v_GEO
					length=5,
				&yyyy 														as &v_TIME,
				%do _i=1 %to &ndim;
					%let dim=%scan(&dimensions, &_i);
					%let lab=%scan(&labels, &_i);
					TMP.&dim 												as &lab,
				%end;
				"PC_POP" 													as &v_UNIT,
				(case when TMP.&v_WEIGHT._PctSum_&corder=. 
					then 0 
					else TMP.&v_WEIGHT._PctSum_&corder
					end) 													as &v_IVALUE,
				"&iflag" 													as &v_IFLAG 
					format=$3. length=3,
				(case when sum(TMP.&v_WEIGHT._N) < 20 
					%if %upcase(&mflag)=YES %then %do;
						or missunrel.pcmiss > 50 
					%end;
					then 2
				  	when sum(TMP.&v_WEIGHT._N) < 50 
					%if %upcase(&mflag)=YES %then %do;
						or missunrel.pcmiss > 20 
					%end;
					then 1
				  	else 0
			      	end) 													as &v_UNREL,
				TMP.&v_WEIGHT._N 											as &v_N,
				sum(TMP.&v_WEIGHT._N) 										as &v_NTOT,
				sum(TMP.&v_WEIGHT._Sum) 									as &v_TOTWGH,
				"&sysdate" 													as lastup,
				"&sysuserid" 												as lastuser,
				/* add the variable itself before insertion */
				&var
				/* this will be dropped */
			FROM WORK.&_tmp as TMP
			%if %upcase(&mflag)=YES %then %do;
				LEFT JOIN missunrel ON (TMP.&v_GEO = missunrel.&v_GEO)
			%end;
			GROUP BY 
				TMP.&v_GEO, 
				%do _i=1 %to &ndim;
					%let dim=%scan(&dimensions, &_i);
					TMP.&dim,
				%end;
				unit;
			)  
		%if &cond^= /*not %macro_isblank(cond)*/ %then %do;
			WHERE &cond
		%end;
		; 
	quit;

	%work_clean(&tmp);
	
	/* reset the format to what it was */
	option fmtsearch=(&_oldfmtpath);

	%exit:
%mend silcx_ind_tabulate;

/** \endcond */
