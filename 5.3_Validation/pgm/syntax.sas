* SYNTAX.SAS;
* load check lists, check syntax and routing and create error lists;
*option notes source source2 nomlogic nomprint;
filename nutsfile "&eusilc/pgm/nuts.csv";                  *** nuts2 codes;  
filename chkfile  "&eusilc/pgm/&ss&yy&f.chk.0sas" lrecl=310; *** checks (macros) to run;
filename prt      "&eusilc/&cc/&ss&yy/&ss&cc&yy&f..lst";   *** error lists; 

DATA _null_;                                                                                                                            
date = date();                                                                                                                          
call symput('datum',put(date,ddmmyyd10.));
if "&ss" = "c" then do;
  call symput('surtyp',"Cross-sectional");
  call symput('suryear',"20&yy");
end;
else do;
  call symput('surtyp',"Longitudinal");
  call symput('suryear',"&yy1-&yy2");
end;
RUN;             

*** Initialize error count***;
PROC SQL;
create table errtab&f
       (varnam char(8) label='Variable Name',
        vval num,
        fval num,
        flag num,
        routing num,
        error num label='Number of Errors');
QUIT; 
*** load nuts codes ***;
%MACRO NUTS;
%if &f=d %then
%do;
 DATA nuts; 
  %if %SYSEVALF(&sysver > 9) %then infile nutsfile MISSOVER DSD firstobs=1 TERMSTR=CRLF;
  %else infile nutsfile MISSOVER DSD firstobs=1;;
  format nutscode $8.;
  input nutscode;
  if substr(nutscode,1,2) = upcase("&cc");
 RUN;
%end;
%MEND;
%NUTS;

*** Run checks and create error lists ***;
OPTIONS nocenter nodate pagesize=50 linesize=75 pageno=1 formchar ='-----';
PROC PRINTTO print=prt new;
RUN;
title1 "&datum";
title2 "&ccnam - &surtyp survey &suryear";
%include chkfile;

title3;
title4;

* put summary to error list and set pointers;
DATA syntax syntaxf flag routing;
retain toterr (0);
set errtab&f end=eof;
if error > 0 then
do;
	toterr = toterr + 1;
	if vval then output syntax;
	else if fval then output syntaxf;
	else if flag then output flag;
	else if routing then output routing;
end;
if eof then call symput("errors",compress(toterr));
RUN; 
PROC SQL;
    title3 "Value errors";
	select varnam, error from syntax;
    title3 "Flag errors";
	select varnam, error from syntaxf;
    title3 "Value<>Flag errors";
	select varnam, error from flag;
    title3 "Routing (-2) errors";
	select varnam, error from routing;
QUIT; 
PROC PRINTTO;
RUN;
title3;

* print summary error list also to report file;
PROC SORT data=errtab&f;
by varnam;
RUN;
DATA _null_;
file report mod;
retain v_err vf_err f_err r_err;
set errtab&f end=eof;
by varnam;

if _N_ = 1 then do;
	put " ";
	put " ";
	put "--------------------- ";
	put "Syntax Checks: &f-file";
	put "--------------------- ";
	put "         |    Value    |    Flag     | Value<>Flag | Routing(-2)";
	put "Variable |    errors   |    errors   |   errors    |   errors";
	put "---------|-------------|-------------|-------------|------------";
end;

if first.varnam then do;
	v_err = .;
	vf_err = .;
	f_err = .;
	r_err = .;
end;
if error > 0 then
do;
	if vval then v_err = error;
	else if fval then vf_err = error;
	else if flag then f_err = error;
	else if routing then r_err = error;
end;
if last.varnam and not (v_err = . and vf_err = . and f_err = . and r_err = .) then 
	put varnam @9 (v_err vf_err f_err r_err) (" | " 11. " | " 11. " | " 11. " | " 11.);
if eof then do;
	put "----------------------------------------------------------------";
	put " ";
	put " ";
end;
RUN; 

/*** write log ***;
PROC SQL;  
     Insert into llog.log
     set date = "&sysdate"d,
	 	 time = "&systime"t,
	 	 user = "&sysuserid",
		 cc = "&cc",
		 yy = 2000+&yy,
		 ss = "&ss",
		 f = "&f",
		 task = "syntax",
		 errors = &errors;		  
QUIT;*/
