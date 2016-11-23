## ds_alter {#sas_ds_alter}
Alter a dastaset using the SQL-based `ALTER TABLE` method.

	%ds_alter(dsn, add=, typ=, modify=, fmt =, lab =, len = , drop = , lib=);
  
### Arguments
* `dsn` : name of the input/output dataset; 	
* `add` : (_option_) clause statement to add given variable(s) to the input `idsn` table; 	
* `typ` : (_option_) data type of the added variables; this option is used only together with the
	clause `add` above;
* `modify` : (_option_) clause statement used to change the width, informat, format, and label of 
	given existing variable(s);
* `fmt, lab` : (_option_) format and label to apply to `modify` clause;	these options are used
	only together with the clause `modify` above; they must be of the same length as `modify`;
* `drop` : (_option_) clause statement used to delete given variable(s) from the input `idsn` 
	table;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
In the table `dsn`, the altered table depending on keyword clauses passed to the macro.

### Examples
Let us consider the test dataset #32 in `WORK`ing library:
geo	   | value  
:-----:|-------:
BE	   |      0 
AT	   |     0.1
BG     |     0.2
LU     |     0.3
FR     |     0.4
IT     |     0.5

we can then run for the macro `%%ds_alter` with the `add` clause:

	%_dstest32;
	%let add=var1 		var2	var3;
	%let typ=char(10) 	num 	char(2);
    %ds_alter(_dstest32, add=&add, typ=&typ);

so as to reset the table `_dstest32` to:
| geo | value | var1 | var2 | var3 |
|:---:|------:|------|------|------|
| BE  |    0  |      |   .  |      |   
| AT  |  0.1  |      |   .  |      |   
| BG  |  0.2  |      |   .  |      |   
| LU  |  0.3  |      |   .  |      |   
| FR  |  0.4  |      |   .  |      |   
| IT  |  0.5  |      |   .  |      |   

Similarly, we can run the macro on test dataset #33:
geo	   | value 
:-----:|------:
BE	   |	  1
AT     |      .
BG	   |      2
LU     |      3
FR     |      .
IT	   |      4
with the `modify` clause:

	%_dstest33;
	%let var=	geo    	value;
    %let len=	20		8;
	%let fmt=	$20.	10.0;
    %let lab=	LAB1 	LAB2;
	%ds_alter(_dstest33, modify=&var, len=&len, fmt=%quote(&fmt), lab=&lab); 

so as to set the output table `_dstest33` to:
  geo  | value  
:-----:|------:
BE	   |   1.00
AT     |      .
BG	   |   2.00
LU     |   3.00
FR     |      .
IT	   |   4.00

Let us finally consider the test dataset #34 which looks like: 
geo	   | time |value
:-----:|-----:|----:
EU27   | 2006 |  1  
EU25   | 2004 |  2  
EA13   | 2001 |  3  
EU27   | 2007 |  4  
EU15   | 2004 |  5  
EA12   | 2007 |  6  
EA12   | 2002 |  7  
EU15   | 2015 |  8  
NMS12  | 2015 |  9  

and run the macro `%%ds_alter` with the `drop` clause:

	%_dstest34;
   	%let var=time value
	%ds_alter(_dstest34, drop=&var);  

the output table `_dstest34` will be set to:
|  geo	 |  
|:------:| 
| EU27   |  
| EU25   |  
| EA13   |   
| EU27   |  
| EU15   |  
| EA12   |  
| EA12   |  
| EU15   |  
| NMS12  |  

Run macro `%%_example_ds_alter` for more examples.

### Notes
1. In short, the macro runs (when one variable is passed to each parameter):

   	PROC SQL;
		ALTER TABLE &lib..&dsn
		ADD &add &typ
		MODIFY &modify FORMAT=&fmt LABEL=&lab LENGTH=&len
        DROP &drop
		;	
	quit;
2. When using `modify` clause, the column's data type is unchanged.

### See also
[%ds_select](@ref sas_ds_select),
[ALTER](https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473671.htm),
[ALTER TABLE](http://support.sas.com/documentation/cdl/en/sqlproc/69049/HTML/default/viewer.htm#n1ckvfae6xf2tyn1nrivm6egpr8b.htm).
