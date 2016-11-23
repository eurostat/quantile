Description
-----------

The programs in this folder are derived from 'legacy' programs in Z:\IDB_RDB\pgm\C_IND.

Contrary to the original files, the new programs contain the macro definition only, not 
its execution, e.g. the original DI01.sas looks like:
		%macro UPD_DI01(yyyy,Ucc,Uccs,flag);
			[...]
			[core of the macro UPD_DI01]
			[...]
		%mend UPD_DI01;
		%UPD_DI01(&year,&cntr,&MS,&flag);
		
while the new created file is:
		%macro UPD_DI01(yyyy,Ucc,Uccs,flag) /store;
			[...]
			[core of the macro UPD_DI01]
			[...]
		%mend UPD_DI01;

The programs are used to create a stored library (hence the '/store' keyword).

Note
----

The programs were extracted from the legacy files using the awk tool, e.g. the following
command is used to generate the desired DI01.sas program:
	$$ cd /z/IDB_RDB/pgm/C_IND
	$$ awk '/mend/{_=NR}{a[NR]=$0}END{for(i=1;i<=_;i++)print a[i]}' DI01.sas > /z/03.Estimation/pgm/RDB/DI01.sas

and running the command for all files:
	$$ for f in *.sas; do 
	> awk '/mend/{_=NR}{a[NR]=$0}END{for(i=1;i<=_;i++)print a[i]}' $f > /z/03.Estimation/pgm/RDB/$f; 
	> done
