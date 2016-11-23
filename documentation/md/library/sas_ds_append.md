## ds_append {#sas_ds_append}
Conditionally append reference datasets to a master dataset using multiple occurences of `PROC APPEND`.

	%ds_append(dsn, idsn, icond=, drop=, cond=, lib=WORK, ilib=WORK);

### Arguments
* `dsn` : input master dataset;
* `idsn` : (list of) input reference dataset(s) to append to the master dataset;
* `drop` : (_option_) list of variable to remove from output dataset; `_ALL_` `_NONE_`
* `icond`: (_option_) condition to apply to the input dataset;
* `cond`: (_option_) condition to apply to the output dataset;
* `lib` : (_option_) name of the library with (all) reference dataset(s); default: `olib=WORK`;
* `ilib` : (_option_) name of the library with master dataset; default: `ilib=WORK`.

### Returns
The table `dsn` is updated using datasets in `idsn`.

### Examples
Let us consider test dataset #32 in `WORK`ing library:
geo	   | value  
:-----:|-------:
BE	   |      0 
AT	   |     0.1
BG     |     0.2
LU     |     0.3
FR     |     0.4
IT     |     0.5
and update it using test dataset #33:
geo	   | value  
:-----:|-------:
BE	   |     1 
AT	   |     .
BG     |     2
LU     |     3
FR     |     .
IT     |     4
For that purpose, we can run for the macro `%%ds_update ` using the `drop`, `icond` and `ocond` 
options as follows:

	%let geo=BE;
	%let cond=(geo = "&geo");
	%let cond=(not(geo = "&geo"));
	%let drop=value;
	%ds_update(_dstest32, _dstest33, drop=&drop, icond=&icond, cond=&ocond);

so as to reset `_dstest32` to the table:
 geo | value  
:---:|-------:
AT	 |     0.1
BG   |     0.2
LU   |     0.3
FR   |     0.4
IT   |     0.5
BE	 |      1 

### Notes
1. The macro `%%ds_append` processes several occurrences of the `PROC APPEND`, _e.g._ in short it runs
something like:

	%do i=1 %to %list_length(&idsn);
		%let _idsn=%scan(&idsn, &_i);
		PROC APPEND
			BASE=&lib..&dsn (WHERE=&cond)
			DATA=&ilib..&_idsn (WHERE=&icond)
			FORCE NOWARN;
		run;
	%end;
	PROC SQL;
		ALTER TABLE &lib..&dsn DROP &drop;	
	quit;
2. If you aim at creating a dataset with `n`-replicates of the same table, _e.g._ running something like:

	   %ds_append(dsn, dsn dsn dsn); * !!! AVOID !!!;
so as to append to `dsn` 3 copies of itself, you should instead consider to copy beforehand the table into 
another dataset to be used as input reference. Otherwise, you will create, owing to the `do` loop above, a 
table with (2^n-1) replicates instead, _i.e._ if you will append to `dsn` (2^3-1)=7 copies of itself in the 
case above. 

### References
1. Zdeb, M.: ["Combining SAS datasets"](http://www.albany.edu/~msz03/epi514/notes/p121_142.pdf).
2. Thompson, S. and Sharma, A. (1999): ["How should I combine my data, is the question"](http://www.lexjansen.com/nesug/nesug99/ss/ss134.pdf).
3. Dickstein, C. and Pass, R. (2004): ["DATA Step vs. PROC SQL: What's a neophyte to do?"](http://www2.sas.com/proceedings/sugi29/269-29.pdf).
4. Philp, S. (2006): ["Programming with the KEEP, RENAME, and DROP dataset options"](http://www2.sas.com/proceedings/sugi31/248-31.pdf).
5. Carr, D.W. (2008): ["When PROC APPEND may make more sense than the DATA STEP"](http://www2.sas.com/proceedings/forum2008/085-2008.pdf).
6. Logothetti, T. (2014): ["The power of PROC APPEND"](http://analytics.ncsu.edu/sesug/2014/BB-18.pdf).

### See also
[APPEND](https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000070934.htm).
