	%_dstest37;
	%_dstest38;
	%let dsn1=_dstest37;
	%let dsn2=_dstest38;
	%let odsn=dsn_merge;

	%let var_key=geo EQ_INC20;
	%let var_add=time;
data &odsn (drop=pp);
	declare hash group (dataset:"&dsn1");
	pp=group.definekey("&var_key");
	pp=group.definedata("&var_add");
	pp=group.definedone();
	do until(eof1);
		set &dsn1 end=eof1;
		pp=group.add();
	end;
	do until(eof2);
		set &dsn2 end=eof2;
		call missing(&var_add);
		pp=group.find();
		if pp=0 then output;
	end;
run;
/* merge one to one */
proc dort 
data test1;
merge _dstest26 _dstest25;
by geo;
run;
data test1;
merge _dstest31 _dstest26;
run;