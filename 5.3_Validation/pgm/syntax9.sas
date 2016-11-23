* SYNTAX9.SAS;
* load check lists, check syntax and routing and create error lists;
* checks high missing values;

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
if "&ss" = "l" then do;
  call symput('surtyp',"Longitudinal");
  call symput('suryear',"&yy1-&yy2");
end;
if "&ss" = "r" then do;
  call symput('surtyp',"Regular-transmission");
  call symput('suryear',"&yy1-&yy2");
end;
if "&ss" = "e" then do;
  call symput('surtyp',"Early-Transmission");
  call symput('suryear',"20&yy");
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
        missng num,
        error num label='Number of Errors');
QUIT; 
/* creation dataset to contain all&f  errors for output  added on 24.06.2014 */
%let y4=%eval(&RYYYY);
%let y1=%eval(&RYYYY -1);
%let y2= %eval(&RYYYY -2);
%let y3= %eval(&RYYYY -3);
 

data VToterr&f;
	varnam="        " ;
	Y_&y3=.;
	Y_&y2=.;
	Y_&y1=.;
	Y_&y4=.;
run;
data FToterr&f;
	varnam="        " ;
	Y_&y3=.;
	Y_&y2=.;
	Y_&y1=.;
	Y_&y4=.;
run;
data VFToterr&f;
	varnam="        " ;
	Y_&y3=.;
	Y_&y2=.;
	Y_&y1=.;
	Y_&y4=.;
run;
data RToterr&f;
	varnam="        " ;
	Y_&y3=.;
	Y_&y2=.;
	Y_&y1=.;
	Y_&y4=.;
run;
data MToterr&f;
	varnam="        " ;
	Y_&y3=.;
	Y_&y2=.;
	Y_&y1=.;
	Y_&y4=.;
run;
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
%macro rep;

%if "&ss" = "l" or "&ss" = "r" %then %do;
*** Run checks and create error lists ***;
OPTIONS nocenter nodate pagesize=50 linesize=75 pageno=1 formchar ='-----';
PROC PRINTTO print=prt new;
RUN;
title5 " ";
title1 "&datum";
title2 "&ccnam - &surtyp survey &suryear";
title3;
%include chkfile;

title3;
title4;

* put summary to error list and set pointers;
DATA syntax syntaxf flag routing pcmiss;
retain toterr (0);
set errtab&f end=eof;
if error > 0 then
do;
	toterr = toterr + 1;
	if vval then output syntax;
	else if fval then output syntaxf;
	else if flag then output flag;
	else if routing then output routing;
	else if missng then output pcmiss;
end;
if eof then call symput("errors",compress(toterr));
RUN; 
*** Initialize error count by years valus/flaf/flag & values/routing/missing  ***;
 data VToterr&f; 
 set VToterr&f;
 if varnam="        "  then delete;
 run;
  data FToterr&f; 
 set FToterr&f;
 if varnam="        "  then delete;
 run;
  data VFToterr&f; 
 set VFToterr&f;
 if varnam="        "  then delete;
 run;
 data RToterr&f; 
 set RToterr&f;
 if varnam="        "  then delete;
 run;
  data MToterr&f; 
 set MToterr&f;
 if varnam="        "  then delete;
 run;

PROC SQL;
 CREATE TABLE VTsum&f AS SELECT a.*,
  b.ERROR as Tot_Error
 FROM VToterr&f as a  LEFT JOIN syntax as b ON (a.varnam = b.varnam) ;
QUIT; 
data  VTsum&f (rename=(varnam=varname));set  VTsum&f;run;
PROC SQL;
 CREATE TABLE FTsum&f AS SELECT a.*,
  b.ERROR as Tot_Error
 FROM FToterr&f as a  LEFT JOIN syntaxf as b ON (a.varnam = b.varnam) ;
QUIT; 
data  FTsum&f (rename=(varnam=varname));set  FTsum&f;run;
PROC SQL;
 CREATE TABLE VFTsum&f AS SELECT a.*,
  b.ERROR as Tot_Error
 FROM VFToterr&f as a  LEFT JOIN flag as b ON (a.varnam = b.varnam) ;
QUIT; 
data VFTsum&f (rename=(varnam=varname));set VFTsum&f;run;
PROC SQL;
 CREATE TABLE RTsum&f AS SELECT a.*,
  b.ERROR as Tot_Error
 FROM RToterr&f as a  LEFT JOIN routing as b ON (a.varnam = b.varnam) ;
QUIT; 
data  RTsum&f (rename=(varnam=varname));set  RTsum&f;run;
 
data MToterr&f ;set MToterr&f;Tot_Error_Number=sum( Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4,0); run;
PROC SQL;
 CREATE TABLE MTsum&f AS SELECT a.*,
  b.ERROR as Pcerror
 FROM MToterr&f as a  LEFT JOIN pcmiss as b ON (a.varnam = b.varnam) ;
QUIT; 
data  MTsum&f (rename=(varnam=varname));set  MTsum&f;run;
/* put summary to error list and set pointers;*/


PROC SQL;
 
    title3 "Value errors by years ";
	/*select varnam, error from syntax;*/
	select varname , Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4, Tot_Error  from VTsum&f;
 
    title3 "Flag errors by years";
	/*select varnam, error from syntaxf;*/
	select varname , Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4, Tot_Error  from FTsum&f;

    title3 "Value<>Flag errors by years";
	/*select varnam, error from flag;*/
	select varname , Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4, Tot_Error from VFTsum&f;


    title3 "Routing (-2) errors by years";
	/*select varnam, error from routing by years ;*/
	select varname , Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4, Tot_Error  from RTsum&f;

    title3 "Missing (-1) errors by years %>5 ";
	/*select varnam, error "% of Errors by years" format=3. from pcmiss;*/
	select varname , Y_&y3 ,Y_&y2 ,Y_&y1 ,Y_&y4, Tot_Error_Number, PcERROR format=3.0 from MTsum&f;
QUIT; 
PROC PRINTTO;
RUN;
title5;

* print summary error list also to report file;
PROC SORT data=errtab&f;
by varnam;
RUN;
DATA _null_;
file report mod;
retain v_err vf_err f_err r_err m_err ;
set errtab&f end=eof;
by varnam;

if _N_ = 1 then do;
	put " ";
	put " ";
	put "--------------------- ";
	put "Syntax Checks: &f-file";
	put "--------------------- ";
	put "         |    Value    |    Flag     | Value<>Flag | Routing(-2) | Missing(-1)";
	put "Variable |    errors   |    errors   |   errors    |   errors    |  values (%)";
	put "---------|-------------|-------------|-------------|-------------|------------";
end;

if first.varnam then do;
	v_err = .;
	vf_err = .;
	f_err = .;
	r_err = .;
	m_err = .;
end;
if error > 0 then
do;
	if vval then v_err = error;
	else if fval then vf_err = error;
	else if flag then f_err = error;
	else if routing then r_err = error;
	else if missng then m_err = error;
end;
if last.varnam and not (v_err = . and vf_err = . and f_err = . and r_err = . and m_err = .) then 
	put varnam @9 (v_err vf_err f_err r_err m_err) (" | " 11. " | " 11. " | " 11. " | " 11. " | " 11.);
if eof then do;
	put "------------------------------------------------------------------------------";
	put " ";
	put " ";
end;
RUN; 
%end;
%else %do;

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
DATA syntax syntaxf flag routing pcmiss;
retain toterr (0);
set errtab&f end=eof;
if error > 0 then
do;
	toterr = toterr + 1;
	if vval then output syntax;
	else if fval then output syntaxf;
	else if flag then output flag;
	else if routing then output routing;
	else if missng then output pcmiss;
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
    title3 "Missing (-1) errors";
	select varnam, error "% of Errors" format=3. from pcmiss;
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
retain v_err vf_err f_err r_err m_err ;
set errtab&f end=eof;
by varnam;

if _N_ = 1 then do;
	put " ";
	put " ";
	put "--------------------- ";
	put "Syntax Checks: &f-file";
	put "--------------------- ";
	put "         |    Value    |    Flag     | Value<>Flag | Routing(-2) | Missing(-1)";
	put "Variable |    errors   |    errors   |   errors    |   errors    |  values (%)";
	put "---------|-------------|-------------|-------------|-------------|------------";
end;

if first.varnam then do;
	v_err = .;
	vf_err = .;
	f_err = .;
	r_err = .;
	m_err = .;
end;
if error > 0 then
do;
	if vval then v_err = error;
	else if fval then vf_err = error;
	else if flag then f_err = error;
	else if routing then r_err = error;
	else if missng then m_err = error;
end;
if last.varnam and not (v_err = . and vf_err = . and f_err = . and r_err = . and m_err = .) then 
	put varnam @9 (v_err vf_err f_err r_err m_err) (" | " 11. " | " 11. " | " 11. " | " 11. " | " 11.);
if eof then do;
	put "------------------------------------------------------------------------------";
	put " ";
	put " ";
end;
RUN; 
%end;
%mend;
%rep;
 