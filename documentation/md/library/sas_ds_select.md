## ds_select {#sas_ds_select}
Select variables from a given dataset using the SQL-based `SELECT` method.

	%ds_select(idsn, odsn, 
			var=, varas=, varop=, 
			where=, groupby=, having=, orderby=, 
			_proc_=, distinct=no, all=no, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : a dataset reference;
* `odsn` : name of the output dataset; 
* `var` : (_option_) list of fields/variables of `idsn` upon which the extraction is performed; default:
	`var` is empty and all variables are selected; note that (see below):
		+ the operation of `varop` (see below) will operate on	these variables only,
		+ all other variables in the dataset can also be selected using the option `all=yes`;
* `varas` : (_option_) list of alias (`AS`) to use for the variables in `var`; if not empty, then should
	 be of same length as `var`; default: empty, _i.e._ the names of the variables are retained;
* `varop` : (_option_) list of unary operations (_e.g._, `min`, `max`, ...) to run (separately) over the 
	list of variables in `var`; if not empty, then should be of same length as `var`; note that the string 
	`ID` (see also variable `G_PING_IDOP`) is used for the identity operation (_i.e._, no operation); default: 
	empty, _i.e._ `ID` is ran over all variables;
* `where` : (_option_) expression used to refine the selection (`WHERE` option); should be passed with 
	`%%str`; default: empty;
* `groupby` : (_option_) list of variables of `idsn` used to group data (`GROUP BY` option); default:
	empty;
* `having` : (_option_) expression used to refine the selection (`HAVING` option); should be passed with 
	`%%str`; default: empty;
* `orderby` : (_option_) list of variables of `idsn` used to group data (`ORDER BY` option); default:
	empty;
* `all` : (_option_) boolean flag (`yes/no`) set to keep all variables from input dataset `idsn`; in 
	practice, a `*` is added to the list of variables in `var` into the `SELECT` operation; default:
	`all=no`, _i.e._ only the variables in `var` are present in the output dataset;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used.
  
### Returns
* `odsn` : name of the output dataset (in `WORK` library); it will contain the selection operated on the 
	original dataset;
* `_proc_` : (_option_) name of a variable containing the `PROC SQL` procedure; when passed, or when the 
	debug mode is set, the operation is not actually ran, but it is returned (as a string) in this variable.

### Examples
Let us consider the test dataset #35:
geo | time | EQ_INC20 | RB050a
----|------|---------:|------:
 BE | 2009 |    10    |   10 
 BE | 2010 |    50    |   10
 BE | 2011 |    60    |   10
 BE | 2012 |    20    |   20
 BE | 2013 |    10    |   20
 BE | 2014 |    30    |   20
 BE | 2015 |    40    |   20
 IT | 2009 |    10    |   10
 IT | 2010 |    50    |   10
 IT | 2011 |    50    |   10
 IT | 2012 |    30    |   20
 IT | 2013 |    30    |   20
 IT | 2014 |    20    |   20
 IT | 2015 |    50    |   20

and run the following:
	
	%let var=   geo time EQ_INC20 RB050a;
	%let varas= geo time income   weight;
	%let varop= ID  ID   ID       min;
	%let where= %str(EQ_INC20>20);
	%let groupby= geo;
	%_dstest35;
	%ds_select(_dstest35, TMP, var=&var, varas=&varas, varop=&varop, distinct=no, where=&where, groupby=&groupby);

to create the output table `TMP`:
geo | time | income | weight
----|------|-------:|-------:
BE  | 2014 |   30   |   10
BE  | 2011 |   60   |   10
BE  | 2010 |   50   |   10
BE  | 2015 |   40   |   10
IT  | 2012 |   30   |   10
IT  | 2011 |   50   |   10
IT  | 2010 |   50   |   10
IT  | 2015 |   50   |   10
IT  | 2013 |   30   |   10
while  in debug mode:

	%let proc=;
	%ds_select(_dstest35, TMP, var=&var, varas=&varas, varop=&varop, distinct=no, where=&where, groupby=&groupby, _proc_=proc);

does not actually run the operation, but instead returns in `proc` the following string that describes the 
implemented procedure:

	PROC SQL noprint; CREATE TABLE WORK.TMP AS SELECT geo, EQ_INC20 AS income, 
		min(RB050a) AS weight FROM WORK._dstest35 WHERE EQ_INC20>20 GROUP BY geo; quit;

Run macro `%%_example_ds_select` for examples.

### Notes
1. In short, when only one variable `var` only is passed (as well as one `varas` identifier and one 
operation `varop` at most), and with `distinct=yes, all=yes`, the macro runs the following `PROC SQL` 
procedure:

	PROC SQL noprint;
		CREATE TABLE &olib..&odsn AS
		SELECT DISTINCT &varop(&var) AS &varas, *
		FROM &ilib..&idsn 
		WHERE &where
		GROUP BY &groupgy
		HAVING &having
		ORDER BY &ordergy
		;
	quit;
2. In debug mode, or when `_proc_` is set, the macro is used to defines the procedure instructions:

	   %let proc=;
	   %ds_select( ... , _proc_=proc);
so that `proc` is set to the procedure that launches the operation (see above), and while the actual 
operation is actually not ran. Further note that in the case the variable `G_PING_DEBUG` is not defined 
in your environment, and `_proc_` is not set, debug mode is ignored (_i.e._, by default the operation 
is ran).
3. For options/clause `where`, `groupby` and `having`, do not specify the corresponding keywords (_i.e._,
`WHERE`, `GROUP BY` and `HAVING` respectively). Ibid, for the `varas` option, do no use the `AS` keyword
in the list of names.
4. Note that while clauses `where` and `having` should be passed using the `%%str` string macro when 
running the process, `%%bquote` should be preferred when running in debug mode.
5. Remember the following differences between the `HAVING` and `WHERE` clauses:

	   DATA test;
	      a = 5; b = 6;
	   RUN;
	   PROC SQL;
		   CREATE TABLE test1 AS
			   SELECT (case when a=5 then 6
		  		   else 7 end) as a, 
			   COUNT(*) AS dummy
		   FROM test
		   GROUP BY a
		   HAVING a=5;
		   CREATE TABLE test2 AS
			   SELECT (case when a=5 then 6
		  		   else 7 end) as a, 
			   COUNT(*) AS dummy
		   FROM test
		   WHERE a=5
		   GROUP BY a;
	   quit;
create respectively `test1` as:
| a | dummy |  
|---|-------|
|   |       |
and `test2` as:
| a | dummy |  
|---|-------|
| 6 |   1   |


### References
1. Williams, C.S. (1999): ["PROC SQL for DATA step die-hards"](http://www.ats.ucla.edu/stat/sas/library/nesug99/ad121.pdf).
2. Dickstein, C. and Pass, R. (2004): ["DATA step vs. PROC SQL: What's a neophyte to do?"](http://www2.sas.com/proceedings/sugi29/269-29.pdf).
3. Williams, C.S. (2008): ["PROC SQL for DATA step die-hards"](http://www.albany.edu/~msz03/epi697/ho/williams.pdf).
4. Marcella, S.P. and Jorgensen, G. (2009): ["PROC SQL: Tips and translations for DATA step users"](http://www.lexjansen.com/nesug/nesug09/bb/BB03.pdf).
5. Bennet, J. and Ross, B. (2015): ["PROC SQL for SQL die-hards"](http://www.pharmasug.org/proceedings/2015/QT/PharmaSUG-2015-QT06.pdf).

### See also
[%ds_append](@ref sas_ds_append), [%ds_isempty](@ref sas_ds_isempty), [%ds_check](@ref sas_ds_check),
[SELECT ](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473678.htm).
