
%macro files;
%if &RCC=GR %then %let RCC=EL;
%if &eDAMIS=Yes %then %do;
	*filerefs to input files;
	filename dfile "&eusilc/&cc/csv/SILC_&RCL.D_A_&RCC._&RYYYY.*.CSV";
	filename rfile "&eusilc/&cc/csv/SILC_&RCL.R_A_&RCC._&RYYYY.*.CSV";
	filename hfile "&eusilc/&cc/csv/SILC_&RCL.H_A_&RCC._&RYYYY.*.CSV";
	filename pfile "&eusilc/&cc/csv/SILC_&RCL.P_A_&RCC._&RYYYY.*.CSV";
%end;
%else %do;
	*filerefs to input files;
	filename dfile "&eusilc/&cc/csv/&D_file";
	filename rfile "&eusilc/&cc/csv/&R_file";
	filename hfile "&eusilc/&cc/csv/&H_file";
	filename pfile "&eusilc/&cc/csv/&P_file";
%end;

%mend;

%files;

* init log ---------------------------------------------------------;
/* to get the current date*/
Data work.log;
	length runchecks $120;
	runchecks = "---"||put("&sysdate"d,ddmmyys10.)||"---"||put("&systime"t,time5.)||"---";
Run;

data info;
   length infoval $120;
   fid=fopen('dfile');
   infoval=finfo(fid,'File Name');
   close=fclose(fid);
   call symput("dfile",infoval);
   fid=fopen('rfile');
   infoval=finfo(fid,'File Name');
   close=fclose(fid);
   call symput("rfile",infoval);
   fid=fopen('hfile');
   infoval=finfo(fid,'File Name');
   close=fclose(fid);
   call symput("hfile",infoval);
   fid=fopen('pfile');
   infoval=finfo(fid,'File Name');
   close=fclose(fid);
   call symput("pfile",infoval);
run;

%MACRO init;

* define survey parameters (country, year, typ) from d-file;
* define survey parameters (country, year, typ) from d-file;
%global Number_T nrow; 

%let Number_T=0;    /* first trasmission */
%if &load ne No and %SYSFUNC(FEXIST(dfile)) %then %do; 
	%if (&ss = l or &ss = r) %then %do;
	proc import datafile=dfile out=dfiley dbms=csv replace;
      getnames=yes;
	run;

	PROC SQL;
	 CREATE TABLE dfileyy AS SELECT distinct
		(MIN(DB010)) AS yy1, 
		(MAX(DB010)) AS yy2 
	 FROM dfiley;
	QUIT;

	DATA _null_;
	set dfileyy;
		yy = yy2 - 2000;
		if yy < 10 then
    		call symput("yy","0"||compress(yy));
    	else call symput("yy",compress(yy));
    	call symput("yy1",compress(yy1));
    	call symput("yy2",compress(yy2));
	RUN;

	%end;

%end;

%else %if (&ss = l or &ss = r) %then %do;
	libname dds "&eusilc/&cc/&ss&yy"; 
	PROC SQL;
	 CREATE TABLE dfileyy AS SELECT distinct
		(MIN(DB010)) AS yy1, 
		(MAX(DB010)) AS yy2 
	 FROM dds.&ss&cc&yy.d;
	QUIT;

	DATA _null_;
	set dfileyy;
		yy = yy2 - 2000;
		if yy < 10 then
    		call symput("yy","0"||compress(yy));
    	else call symput("yy",compress(yy));
    	call symput("yy1",compress(yy1));
    	call symput("yy2",compress(yy2));
	RUN;
%end;

filename ccfile "&eusilc/pgm/country.csv"; *** country labels;  

DATA _null_; /* assign label to country code*/
 %if %SYSEVALF(&sysver > 9) %then infile ccfile MISSOVER DSD firstobs=1 TERMSTR=&del /*TERMSTR=CRLF*/;
 %else infile ccfile MISSOVER DSD firstobs=1;;
 format code $2.;
 format ccname $20.;
 input code ccname;
 if lowcase(code) = "&cc" then call symput("ccnam",compress(ccname));
RUN;

/* fill the log when starting the checks */



%if (&ss=l or &ss=r) and not (&yy1 > 2002 and &yy2 > 2003 and &yy1 < &yy2) %then %do;

	%if (&ss=l) %then %do;
		%let par=ERROR: Longitudinal data! (range of years);
		%let ok=0;
	%end;
	%if (&ss=r) %then %do;
		%let par=ERROR: Regular data! (range of years);
		%let ok=0;
	%end;
%end;
%else %if &cc= or &yy= or &ss= %then %do;
	%let par=ERROR: checks cannot run. Verify D-file;
	%let ok=0;
%end;

%else %do;
	%if &ss=e %then %do;
		%let ssl=early_transmission;
		%let par=Country: %SYSFUNC(upcase(&cc)) - Year: 20&yy - Survey: &ssl;	
    %end;
	%if &ss=c %then %do;
		%let ssl=cross-sectional;
		%let par=Country: %SYSFUNC(upcase(&cc)) - Year: 20&yy - Survey: &ssl;	
    %end;
	%if &ss=l %then %do;
		%let ssl=longitudinal;
		%let par=Country: %SYSFUNC(upcase(&cc)) - Years: &yy1-20&yy - Survey: &ssl;	
	%end;
	%if &ss=r %then %do;
		%let ssl=regular;
		%let par=Country: %SYSFUNC(upcase(&cc)) - Years: &yy1-20&yy - Survey: &ssl;	
	%end;
	%let ok=1;
%end;

PROC SQL;  
     Insert into log
     set runchecks="&par";		  
QUIT;

* Verify if output directories exist;

%let ok1=-1;
%if &ok=1 %then
%do;
  %let ok1=1;
	filename dirss "&eusilc/&cc/&ss&yy";
	%let rc=%SYSFUNC(FEXIST(dirss));
	%if &rc=0 %then %let ok1=0;
%end;	 
%if &ok1=0 %then %do;

PROC SQL;  
     Insert into log
     set runchecks=">>>>> ERROR: create first necessary directories!"; 		  
QUIT;

%end;
%else %do;
  *assign report file;
  options pagesize=5000;
  filename report "&eusilc/&cc/&ss&yy/&ss&cc&yy.REP.lst"; 
  PROC PRINTTO log=report new;
  RUN;
  	%put date = &sysdate;
	%put time = &systime;
	%put user = &sysuserid;
	%put version = 3.9.2.EG;
	%put release = &sysver;
	%put -------------------------------------------------;
	%put survey = &ssl;
	%if &ss = l or &ss= r  %then
		%put year(s) = &yy1 - 20&yy;
	%else %put year(s) = 20&yy;
	%put country = %SYSFUNC(upcase(&cc)) (&ccnam);
	%put -------------------------------------------------;
  PROC PRINTTO;
  RUN;

  *assign data library;
  libname dds "&eusilc/&cc/&ss&yy"; 
  libname back "&eusilc/&cc/tmp"; 

%end;

%MEND init;

%MACRO load;
  *load data;
  %let loadOK=1; 
  *D-file;
  %if %SYSFUNC(FEXIST(dfile)) %then
  %do;
	%let f=d;
	%let par=Loading dfile < &dfile;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
    %let loadOK=0; 
	%let par=! File %sysfunc(pathname(dfile)) does not exist; 
  %end;

	PROC SQL;  
     Insert into log
     set runchecks="&par";		  
    QUIT;

*R-file;
  %if %SYSFUNC(FEXIST(rfile)) %then
  %do;
	%let f=r;
	%let par=Loading rfile < &rfile;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
    %let loadOK=0; 
	%let par=! File %sysfunc(pathname(rfile)) does not exist; 
  %end;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

 *H-file;
  %if %SYSFUNC(FEXIST(hfile)) %then
  %do;
	%let f=h;
	%let par=Loading hfile < &hfile;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
    %let loadOK=0; 
	%let par=! File %sysfunc(pathname(hfile)) does not exist; 
  %end;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

  *P-file;
  %if %SYSFUNC(FEXIST(pfile)) %then
  %do;
	%let f=p;
	%let par=Loading pfile < &pfile;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
    %let loadOK=0; 
	%let par=! File %sysfunc(pathname(pfile)) does not exist; 
  %end;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

%MEND load;

%MACRO chk1; 
  *check syntax;
  *D-file;

  %let f=d;
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then %do;
	%include "&eusilc/pgm/syntax9.sas"; /*%end;*/
	%let par=* Syntax checks: &errors errors in &f.file;
  %end;
  %else %do;
	  %let par=! &&&f.file not found !;
	  %end;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

  *R-file;
  %let f=r;
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then %do;
	%include "&eusilc/pgm/syntax9.sas"; /*%end;*/
	%let par=* Syntax checks: &errors errors in &f.file;
  %end;
  %else %do;
	  %let par=! &&&f.file not found !;
	  %end;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

  *H-file;
  %let f=h;
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then %do;
	%include "&eusilc/pgm/syntax9.sas"; /*%end;*/
	%let par=* Syntax checks: &errors errors in &f.file;
  %end;
  %else %do;
	  %let par=! &&&f.file not found !;
	  %end;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

  *P-file;
  %let f=p;
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then %do;
	%include "&eusilc/pgm/syntax9.sas"; /*%end;*/
	%let par=* Syntax checks: &errors errors in &f.file;
  %end;
  %else %do;
	  %let par=! &&&f.file not found !;
  %end;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

%MEND chk1;

%MACRO chk2;
  *Logical;
  
	%include "&eusilc/pgm/chkplus.sas";
	%let par=* Logical checks: &errors errors;

  PROC SQL;  
     Insert into log
     set runchecks="&par";		  
  QUIT;

%MEND chk2;

%macro alll;
%init;
%if &ok1=1 %then %do;
	%if &load ne No %then %load;
	%else %let loadOK=1; 
	%if &loadOK %then %do;
		%chk1;
	
		%chk2;
		%if &yy=07 and &ss=c and &load ne No and &cc ne at %then %do;
			%put *** subtract PY080G ***;
			%include "&eusilc/pgmEG/EG_C07MOD.sas";
		%end;
	%end;
%end;

%mend alll;
%alll;

ODS listing close;
title; footnote;
ODS HTML(ID=EGHTML) FILE=EGHTML STYLE=EGDefault;
%macro No_Input;

%if &Number_T=0 %then %let Label_Tras=First Trasmission;
%if &Number_T=0 and  %sysfunc(exist(Countryfile)) %then %do;
		 proc print data=Countryfile style(header) =[background=CRIMSON foreground=white TEXTALIGN= c] noobs label
 				   style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
                   cellwidth = 3cm};
		
		    title1 c=CX172B6A "Datafile  not available for the comparition &label_Tras; ";
		run;
%end;
%mend;
%No_Input;

Proc print data=log label noobs;
var runchecks;

Run; 
/*
PROC DATASETS lib=work kill nolist;

QUIT; 

 





