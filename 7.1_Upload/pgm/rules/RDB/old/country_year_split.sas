%macro country_year_split(cc, nameY) /store;
/* macro to create line by line for each indicators */
%let Nyear=1;
%let Nctry=1;
%let year1=%scan(&NameY,&Nyear,-);
%let ctr=%scan(&cc,&Nctry);
%do  %while(&year1 ne ); 
  %do  %while(&ctr ne ); 
 
    PROC SQL;
    CREATE TABLE work.syslog AS
         SELECT 
			 "&sysdate"d as data format=DDMMYYS10.,
		 "&ctr" as country format= $5. length=5,
		"&year1" as year,
		 t as indic format= $10. length=8,
		 u as userid
	  	from test;
		quit;

		 %if not %sysfunc(exist(sendlog1)) %then %do;
		 	data sendlog1; set syslog;run;
		 %end;
		 %else %do;
		 data sendlog1;set sendlog1 syslog;run;
		 %end;
  	%let Nctry=%eval(&Nctry+1);                                  
  	%let ctr=%scan(&cc,&Nctry);;
%end;
%let Nctry=1;
%let ctr=%scan(&cc,&Nctry);;
%let Nyear=%eval(&Nyear+1);                                  
%let year1=%scan(&NameY,&Nyear,-);;
%end;
%mend;