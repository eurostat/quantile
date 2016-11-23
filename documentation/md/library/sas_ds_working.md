## ds_working {#sas_ds_working}
Create a working copy of a given dataset.

	%ds_working(idsn, odsn, mirror=LIKE, where=, groupby=, having=, ilib=);

### Arguments
* `idsn` : a dataset reference;
* `mirror` : (_option_) type of `copy` operation used for creating the working dataset, _i.e._ either
	an actual copy of the table (`mirror=COPY`) or simply a shaping of its structure (`mirror=LIKE`); 
	default: `mirror=LIKE`; 
* `groupby, where, having` : (_option_) expressions used to refine the selection when `mirror=COPY`,
	like in a `SELECT` statement of `PROC SQL` (`GROUP BY, WHERE, HAVING` clauses); these options are
	therefore incompatible with `mirror=LIKE`; note that `where` and `having` should be passed with 
	`%%quote`; see also [%ds_select](@ref sas_ds_select); default: empty;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
`odsn` : name of the output dataset (in `WORK` library) where a copy of the original dataset or its
	structure is stored.

### Example
For instance, we can run:

	%ds_working(idsn, odsn, mirror=COPY, where=%quote(var=1000));

so as to retrieve:

	DATA WORK.&odsn;
		SET &ilib..&idsn;
		WHERE &var=1000; 
	run; 

See `%%_example_ds_working` for more examples.

### Note
The command `%ds_working(idsn, odsn, mirror=COPY, ilib=ilib)` consists in running:

	DATA WORK.&odsn;
		SET &ilib..&idsn;
	run; 

while the command `%ds_working(idsn, odsn, mirror=LIKE, ilib=ilib)` is equivalent to:

	PROC SQL noprint;
		CREATE TABLE WORK.&odsn like &ilib..&idsn; 
	quit; 

### See also
[%ds_select](@ref sas_ds_select).
