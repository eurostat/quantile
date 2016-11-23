* CHKPLUS.SAS;
* load check lists, create work dataset, do structural checks and create error lists;
*option notes source source2 nomlogic nomprint;

filename chkplist "&eusilc/pgm/&ss&yy.chkl.0sas" ;         *** macros to run with params;
filename prt1     "&eusilc/&cc/&ss&yy/&ss&cc&yy.L.lst";    *** error lists; 

/* creation dataset to contain all errors for output  added on 24.06.2014 */
%let y4=%eval(&RYYYY);
%let y1=%eval(&RYYYY -1);
%let y2= %eval(&RYYYY -2);
%let y3= %eval(&RYYYY -3);
 

data Toterr;
	cod=.;
	Y_&y3=.;
	Y_&y2=.;
	Y_&y1=.;
	Y_&y4=.;
run;


*** Load checks from csv-file and create chklist.tmp ***;
DATA _null_;                                                                                                                            
date = date();                                                                                                                          
call symput('datum',put(date,ddmmyyd10.));
if "&ss" = "c" then do;
  call symput('surtyp',"Cross-sectional");
  call symput('suryear',"20&yy");
end;
if "&ss" = "l" then do;
  call symput('surtyp',"Longitudinal");
  call symput('suryear',"&yy1-&yy2");
end;
if "&ss" = "r" then do;
  call symput('surtyp',"regular-Transmission");
  call symput('suryear',"&yy1-&yy2");
end;
if "&ss" = "e" then do;
  call symput('surtyp',"Early-Transmission");
  call symput('suryear',"20&yy");
end;
RUN;                                                

*** Initialize error count***;
PROC SQL;
create table errtabl
       (cod num label='Error Code',
        error num label='Number of Errors');
QUIT; 


*** Run checks and create error lists ***;
OPTIONS nocenter nodate pagesize=40 linesize=116 pageno=1 formchar ='-----';
*orientation=landscape;
PROC PRINTTO print=prt1 new;
RUN;
%include chkplist;

title3;
title4;
*** Initialize error count by years ***;
 data Toterr; 
 set Toterr;
 if cod= . then delete;
 run;

PROC SQL;
 CREATE TABLE Tsum AS SELECT a.*,
  b.error
 FROM Toterr as a  LEFT JOIN errtabl as b ON (a.cod = b.cod) ;
QUIT; 
/* put summary to error list and set pointers;*/
 
PROC SQL;
    title1 "&datum";
	title2 "&ccnam - &surtyp survey &suryear";
    title3 "Logical errors by year ";
	select cod, Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4, error from Tsum;
	;
QUIT; 
PROC PRINTTO;
RUN;
title3;
DATA _null_;

set Tsum end=eof;

RUN; 
* put summary to error list and set pointers;

filename report   "&eusilc/&cc/&ss&yy/&ss&cc&yy.REP.lst";    *** error lists; 

PROC PRINTTO print=report  ;
RUN;

 
PROC SQL;
  
	title1 "---------------------";
    title2 "Logicals Checks";
    title3 "---------------------";
	select cod, Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4, error from Tsum;
	;
QUIT;  
PROC PRINTTO;
RUN;
title3; 
DATA _null_;

set Tsum end=eof;

RUN; 