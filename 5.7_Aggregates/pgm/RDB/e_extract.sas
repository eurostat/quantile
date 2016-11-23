%macro early(tab);
%if &year >2013 %then %do;
	%if &tab=mddd11 %then %do;
		data extract;set rdb.&tab (where=(GEO="&cntr" and time = &year ));
		run;
	%end;
	%if &tab=mddd13 %then %do;
		data extract;
		set rdb.&tab (where=(GEO="&cntr" and time = &year and quantile='TOTAL'));
		run;
	%end;
DATA  e_rdb.e_&tab ;
set e_rdb.e_&tab(where=(not(time = &year and geo = "&cntr" )))
    work.extract;
RUN;
%end;
%mend;
