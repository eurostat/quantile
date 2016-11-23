 *options source2 notes;
 *options mlogic mprint symbolgen;

* files window;
%MACRO wfiles;
%if &SYSSCP=WIN %then %do;
  options noxwait;
%end;
%if &jump %then
%do; 
  %window Input color=white columns=60 rows=25 icolumn=10 irow=10
    #2  @10  'Welcome to EU-SILC Checking Programs' attr=highlight color=blue
    #4  @3  "Enter input files:"
    #6  @5  "Path:" color=green +1 csvfiles 40 attr=(highlight,rev_video) color=green
    #8  @8  "D:" color=green +1 dfile 40 attr=(highlight,rev_video) color=green
    #9  @8  "R:" color=green +1 rfile 40 attr=(highlight,rev_video) color=green
	#10 @8  "H:" color=green +1 hfile 40 attr=(highlight,rev_video) color=green
	#11 @8  "P:" color=green +1 pfile 40 attr=(highlight,rev_video) color=green
    #13 @8  "Load csv-files before checking? (y/n)" color=green +1 load 1 attr=(highlight,rev_video) color=green
	#14 @8  "if n enter: c/l" color=green
			+1 Tss 1 attr=(highlight,rev_video) color=green
			+1 "cc" color=green +1 Tcc 2 attr=(highlight,rev_video) color=green
			+1 "yyyy[-yyyy(l)]" color=green +1 Tyy 4 attr=(highlight,rev_video) color=green
			 "-" color=green  Tyy2 4 attr=(highlight,rev_video) color=green
	#17 @5 'ENTER path and filenames or PUSH F3 to continue';

  %DISPLAY Input;

* write files.txt;
  DATA _null_;
    file "&eusilc/pgm/lastfiles.txt"; 
	put "%nrstr(%let )" "Tss=&Tss;             /* typ last files loaded or checked */";
	put "%nrstr(%let )" "Tcc=&Tcc;             /* country last files loaded or checked */";
	put "%nrstr(%let )" "Tyy=&Tyy;             /* year/year1 last files loaded or checked */";
	put "%nrstr(%let )" "Tyy2=&Tyy2;           /* year2 last files loaded or checked */";
    file "&eusilc/pgm/files.txt"; 
    put "/* input data files (.csv) */";
    put "%nrstr(%let )" "csvfiles=&csvfiles;     /* path to input files */";
    put "%nrstr(%let )" "dfile=&dfile;           /* D-file */";
    put "%nrstr(%let )" "rfile=&rfile;           /* R-file */";
    put "%nrstr(%let )" "hfile=&hfile;           /* H-file */";
    put "%nrstr(%let )" "pfile=&pfile;           /* P-file */";
    put "%nrstr(%let )" "load=&load;             /* load files before checking */"; 
  RUN;

%end;
%MEND;
%WFILES;

%include "&eusilc/pgm/files.txt"; /* input files */
%include "&eusilc/pgm/lastfiles.txt"; /* input files */

*filerefs to input files;
filename dfile "&csvfiles.&dfile";
filename rfile "&csvfiles.&rfile";
filename hfile "&csvfiles.&hfile";
filename pfile "&csvfiles.&pfile";



* message window; 
%window Checks color=yellow columns=80 rows=30 icolumn=10 irow=10
group=head
#2 @14  'EU-SILC Checking Programs' attr=(highlight,underline) color=blue
group=par
#4 @2  par color=magenta epar attr=highlight color=orange
group=msgld
#6 @2  emsgld attr=highlight color=orange msgld color=green
group=msglr
#7 @2  emsglr attr=highlight color=orange msglr color=green
group=msglh
#8 @2  emsglh attr=highlight color=orange msglh color=green
group=msglp
#9 @2  emsglp attr=highlight color=orange msglp color=green
group=msgd
#10 @2  emsgd attr=highlight color=orange msgd color=green
group=msgr
#11 @2  emsgr attr=highlight color=orange msgr color=green
group=msgh
#12 @2  emsgh attr=highlight color=orange msgh color=green
group=msgp
#13 @2  emsgp attr=highlight color=orange msgp color=green
group=msgl
#14 @2 emsgl attr=highlight color=orange msgl color=green
group=msgw
#15 @2 emsgw attr=highlight color=orange msgw color=green /* weight check*/
group=msga
#16 @2 emsga attr=highlight color=orange msga color=green /* analysis*/
group=msgo
#17 @2 emsgo attr=highlight color=orange msgo color=green /* outliers*/
group=msgc
#18 @2 emsgc attr=highlight color=orange msgc color=green /* cross comparison with last year*/
group=msgt
#19 @2 emsgt attr=highlight color=orange msgc color=green /* cross comparison with last trasmission*/
group=msglw
#20 @2 emsglw attr=highlight color=orange msgc color=green /* L weights checks*/
group=end
#21 @14 'Press ENTER to finish';

%MACRO init;
%global ok1;
%global Number_T;
%let Number_T=0;
%DISPLAY Checks.head noinput;
* define parameters using d-file;
%let par=Defining survey parameters ...;
%let epar=;
%DISPLAY Checks.par noinput;

* define survey parameters (country, year, typ) from d-file;
%if &load ne n %then %do; 

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

* write lastfiles.txt;
  DATA _null_;
    file "&eusilc/pgm/lastfiles.txt"; 
	put "%nrstr(%let )" "Tss=&ss;             /* typ last files loaded or checked */";
	put "%nrstr(%let )" "Tcc=&cc;             /* country last files loaded or checked */";
	%if (&ss = c or &ss = e) %then %do;
		put "%nrstr(%let )" "Tyy=20&yy;       /* year/year1 last files loaded or checked */";
	    put "%nrstr(%let )" "Tyy2=;           /* year2 last files loaded or checked */";
	%end;
	%if (&ss = l or &ss = r) %then %do;
		put "%nrstr(%let )" "Tyy=&yy1;             /* year/year1 last files loaded or checked */";
    	put "%nrstr(%let )" "Tyy2=&yy2;           /* year2 last files loaded or checked */";
  	%end;
  RUN;
%end;
%else %do;
	%let ss=&Tss;
	%let cc=&Tcc;
	%if (&Tss = c or &Tss = e) %then %let yy=%substr(&Tyy,3,2);
	%else %do;
		%let yy=%substr(&Tyy2,3,2); 
		%let yy1=&Tyy; 
		%let yy2=&Tyy2; 
		%end;
	%end;

filename ccfile "&eusilc/pgm/country.csv"; *** country labels;  
DATA _null_;
 %if %SYSEVALF(&sysver > 9) %then infile ccfile MISSOVER DSD firstobs=1 TERMSTR=CRLF;
 %else infile ccfile MISSOVER DSD firstobs=1;;

 format code $2.;
 format ccname $20.;
 input code ccname;
 if lowcase(code) = "&cc" then call symput("ccnam",compress(ccname));
RUN;


%if (&ss = l or &ss = r) and not (&yy1 > 2002 and &yy2 > 2003 and &yy1 < &yy2) %then %do;
	%if (&ss=l) %then %do;
		%let par=ERROR: Longitudinal data! (range of years);
		%let ok=0;
	%end;
	%if (&ss=r) %then %do;
		%let par=ERROR: Regular data! (range of years);
		%let ok=0;
	%end;
%end;
%else %if &cc= or &yy= or &ss= %then
%do;
	%let par=;	
	%let epar=ERROR: checks cannot run. Verify D-file;
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
	%let epar=;
	%let ok=1;
%end;
%DISPLAY Checks.par noinput;

* Verify if output directories exist and create them if necessary;
%let ok1=-1;
%if &ok=1 %then
%do;
  %let ok1=1;
  %if &SYSSCP=WIN %then
  %do;
    * working in Windows environment;
	filename dircc "&eusilc\&cc";
	%let rc=%SYSFUNC(FEXIST(dircc));
	%if &rc=0 %then
	%do;
	  %sysexec md &eusilc/&cc;
	  * verify again if dir now exist (return code from sysexec is not coherent);
	  %let rc=%SYSFUNC(FEXIST(dircc));
	  %if &rc=0 %then %let ok1=0;
        %end;

	filename dirtmp "&eusilc\&cc\tmp";
	%let rc=%SYSFUNC(FEXIST(dirtmp));
	%if &rc=0 %then
	%do;
	  %sysexec md &eusilc\&cc\tmp;
	  * verify again if dir now exist (return code from sysexec is not coherent);
	  %let rc=%SYSFUNC(FEXIST(dirtmp));
	  %if &rc=0 %then %let ok1=0;
	%end;	 

	filename dirss "&eusilc\&cc\&ss&yy";
	%let rc=%SYSFUNC(FEXIST(dirss));
	%if &rc=0 %then
	%do;
	  %sysexec md &eusilc\&cc\&ss&yy;
	  * verify again if dir now exist (return code from sysexec is not coherent);
	  %let rc=%SYSFUNC(FEXIST(dirss));
	  %if &rc=0 %then %let ok1=0;
	%end;
  %end;
  %else 
  %do;
  * working in UNIX environment;
	filename dircc "&eusilc/&cc";
	%let rc=%SYSFUNC(FEXIST(dircc));
	%if &rc=0 %then
	%do;
	  %sysexec mkdir &eusilc/&cc;
	  * verify again if dir now exist (return code from sysexec is not coherent);
	  %let rc=%SYSFUNC(FEXIST(dircc));
	  %if &rc=0 %then 
            %let ok1=0;
	%end;

	filename dirtmp "&eusilc/&cc/tmp";
	%let rc=%SYSFUNC(FEXIST(dirtmp));
	%if &rc=0 %then
	%do;
	  %sysexec mkdir &eusilc/&cc/tmp;
	  * verify again if dir now exist (return code from sysexec is not coherent);
	  %let rc=%SYSFUNC(FEXIST(dirtmp));
	  %if &rc=0 %then %let ok1=0;
	%end;	 

	filename dirss "&eusilc/&cc/&ss&yy";
	%let rc=%SYSFUNC(FEXIST(dirss));
	%if &rc=0 %then
	%do;
	  %sysexec mkdir &eusilc/&cc/&ss&yy;
	  * verify again if dir now exist (return code from sysexec is not coherent);
	  %let rc=%SYSFUNC(FEXIST(dirss));
	  %if &rc=0 %then %let ok1=0;
	%end;	
  %end;	
%end;	 

%if &ok1=0 %then
%do;
	%let msgld=;
	%let emsgld=ERROR: Cannot create default directories. See User guide; 
	%DISPLAY Checks.msgld noinput;
%end;
%else %if &ok1=1 %then %do;
    *** Initialize logfile (if does not exist)***;
  	*assign log library;
    libname llog "&eusilc/&cc";
	%if not %sysfunc(exist(llog.log)) %then
	%do;			
	    PROC SQL;
	      create table llog.log
	       (date num format=ddmmyys10. label='Date',
     	  	time num format=time5. label='Time',
	 	user char(8) label='User',
		cc char(2) label='Country',
		yy num label='Year',
		ss char(1) label='Typ of Survey',
		f char(1) label='File',
		task char(12) label='Task',
		errors num label='Errors');
	    QUIT;
	%end;
	
  *assign report file;
  filename report "&eusilc/&cc/&ss&yy/&ss&cc&yy.REP.lst"; 
  PROC PRINTTO log=report new;
  RUN;
  	%put date = &sysdate;
	%put time = &systime;
	%put user = &sysuserid;
	%put version = 3.9.2;
	%put release = &sysver;
	%put -------------------------------------------------;
	%put survey = &ssl;
	%if &ss = l or &ss= r %then
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
  *D-file;
  %let msgld=;
  %let emsgld=;
  %if %SYSFUNC(FEXIST(dfile)) %then
  %do;
	%let f=d;
	%let msgld=Loading &csvfiles.&dfile;
	%DISPLAY Checks.msgld noinput;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
	%let emsgld=File &csvfiles.&dfile does not exist; 
	%DISPLAY Checks.msgld noinput;
  %end;
  *R-file;
  %let msglr=;
  %let emsglr=;
  %if %SYSFUNC(FEXIST(rfile)) %then
  %do;
	%let f=r;
	%let msglr=Loading &csvfiles.&rfile;
	%DISPLAY Checks.msglr noinput;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
	%let emsglr=File &csvfiles.&rfile does not exist; 
	%DISPLAY Checks.msglr noinput;
  %end;
  *H-file;
  %let msglh=;
  %let emsglh=;
  %if %SYSFUNC(FEXIST(hfile)) %then
  %do;
	%let f=h;
	%let msglh=Loading &csvfiles.&hfile;
	%DISPLAY Checks.msglh noinput;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
	%let emsglh=File &csvfiles.&hfile does not exist; 
	%DISPLAY Checks.msglh noinput;
  %end;
  *P-file;
  %let msglp=;
  %let emsglp=;
  %if %SYSFUNC(FEXIST(pfile)) %then
  %do;
	%let f=p;
	%let msglp=Loading &csvfiles.&pfile;
	%DISPLAY Checks.msglp noinput;
	%include "&eusilc/pgm/load7.sas";
  %end; 
  %else %do;
	%let emsglp=File &csvfiles.&pfile does not exist; 
	%DISPLAY Checks.msglp noinput;
  %end;

%MEND load;

%MACRO chk1; 
  *check syntax;
  *D-file;
  %let f=d;
  %let msg&f=;
  %let emsg&f=;
  %let &f.file=&f-file(&eusilc/&cc/&ss&yy : &ss&cc&yy.&f);
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then
  %do;
	%let msg&f=Checking syntax of &&&f.file;
	%DISPLAY Checks.msgd noinput;
	%if &yy<08 %then %do; %include "&eusilc/pgm/syntax.sas"; %end;
	%else %do; %include "&eusilc/pgm/syntax9.sas"; %end;
	%if &errors=0 %then 
	%do;
	  %let msg&f=No syntax errors in &&&f.file;
	  %DISPLAY Checks.msgd noinput;
	%end;
	%else %do;
	  %let msg&f=;
	  %let emsg&f=&errors syntax errors in &&&f.file;
	  %DISPLAY Checks.msgd noinput;
	%end;
  %end;
  %else %do;
	  %let msg&f=;
	  %let emsg&f=&&&f.file not found !;
	  %DISPLAY Checks.msgd noinput;
	  %end;
  *R-file;
  %let f=r;
  %let msg&f=;
  %let emsg&f=;
  %let &f.file=&f-file(&eusilc/&cc/&ss&yy : &ss&cc&yy.&f);
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then
  %do;
	%let msg&f=Checking syntax of &&&f.file;
	%DISPLAY Checks.msgr noinput;
	%if &yy<08 %then %do; %include "&eusilc/pgm/syntax.sas"; %end;
	%else %do; %include "&eusilc/pgm/syntax9.sas"; %end;
	%if &errors=0 %then 
	%do;
	  %let msg&f=No syntax errors in &&&f.file;
	  %DISPLAY Checks.msgr noinput;
	%end;
	%else %do;
	  %let msg&f=;
	  %let emsg&f=&errors syntax errors in &&&f.file;
	  %DISPLAY Checks.msgr noinput;
	%end;
  %end;
  %else %do;
	  %let msg&f=;
	  %let emsg&f=&&&f.file not found !;
	  %DISPLAY Checks.msgr noinput;
	  %end;
  *H-file;
  %let f=h;
  %let msg&f=;
  %let emsg&f=;
  %let &f.file=&f-file(&eusilc/&cc/&ss&yy : &ss&cc&yy.&f);
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then
  %do;
	%let msg&f=Checking syntax of &&&f.file;
	%DISPLAY Checks.msgh noinput;
	%if &yy<08 %then %do; %include "&eusilc/pgm/syntax.sas"; %end;
	%else %do; %include "&eusilc/pgm/syntax9.sas"; %end;
	%if &errors=0 %then 
	%do;
	  %let msg&f=No syntax errors in &&&f.file;
	  %DISPLAY Checks.msgh noinput;
	%end;
	%else %do;
	  %let msg&f=;
	  %let emsg&f=&errors syntax errors in &&&f.file;
	  %DISPLAY Checks.msgh noinput;
	%end;
  %end;
  %else %do;
	  %let msg&f=;
	  %let emsg&f=&&&f.file not found !;
	  %DISPLAY Checks.msgh noinput;
	  %end;
  *P-file;
  %let f=p;
  %let msg&f=;
  %let emsg&f=;
  %let &f.file=&f-file(&eusilc/&cc/&ss&yy : &ss&cc&yy.&f);
  %if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then
  %do;
	%let msg&f=Checking syntax of &&&f.file;
	%DISPLAY Checks.msgp noinput;
	%if &yy<08 %then %do; %include "&eusilc/pgm/syntax.sas"; %end;
	%else %do; %include "&eusilc/pgm/syntax9.sas"; %end;
	%if &errors=0 %then 
	%do;
	  %let msg&f=No syntax errors in &&&f.file;
	  %DISPLAY Checks.msgp noinput;
	%end;
	%else %do;
	  %let msg&f=;
	  %let emsg&f=&errors syntax errors in &&&f.file;
	  %DISPLAY Checks.msgp noinput;
	%end;
  %end;
  %else %do;
	  %let msg&f=;
	  %let emsg&f=&&&f.file not found !;
	  %DISPLAY Checks.msgp noinput;
	  %end;


  %MEND chk1;

%MACRO chk2;

  *Logical;
  %let msgl=;
  %let emsgl=;
    %let msgl=Running logical checks;
	%DISPLAY Checks.msgl noinput;
	%include "&eusilc/pgm/chkplus.sas";
	%if &errors=0 %then 
	%do;
	  %let msgl=No logical errors;
	  %DISPLAY Checks.msgl noinput;
	%end;
	%else %do;
	  %let msgl=;
	  %let emsgl=&errors logical errors;
      %DISPLAY Checks.msgl noinput;
	%end;

%MEND chk2;

%macro c_wgt;

%if (&ss= c or &ss = e or &ss = r) %then %do;
  %let msgw=;
  %let emsgw=;
    %let msgw=Running cross-sectional weight checks;
	%DISPLAY Checks.msgw noinput;
	%include "&eusilc/pgm/C_weights.sas";  /* run program */
%end;
%mend c_wgt;

%macro l_wgt;

%if &ss = l or &ss= r %then %do;
  %let msgw=;
  %let emsgw=;
    %let msgw=Running longitudinal weight checks;
	%DISPLAY Checks.msgw noinput;
	%include "&eusilc/pgm/L_weights.sas";  /* run program */
	%include "&eusilc/pgm/DB090.sas";  /* run program */
	%include "&eusilc/pgm/DB095.sas";  /* run program */
	%include "&eusilc/pgm/RB060.sas";  /* run program */
	%include "&eusilc/pgm/RB062.sas";  /* run program */
	%include "&eusilc/pgm/RB063.sas";  /* run program */
	%include "&eusilc/pgm/RB064.sas";  /* run program */
	%include "&eusilc/pgm/PB050.sas";  /* run program */
	%include "&eusilc/pgm/PB080.sas";  /* run program */
%end;
%mend l_wgt;


%macro analysis;
%if (&ss= c or &ss = e or &ss = r) %then %do;
  %let msga=;
  %let emsga=;
  %let msga=Running Analysis;
  %DISPLAY Checks.msga noinput;
  %include "&eusilc/pgm/analysis.sas";  /* run program */
%end;
%mend analysis;

%macro C_outliers;
%if &ss= c or &ss = r %then %do;
  %let msgo=;
  %let emsgo=;
  %let msgo=Running outliers;
  %DISPLAY Checks.msgo noinput;
  %include "&eusilc/pgm/C_outliers.sas";  /* run program */
%end;
%mend C_outliers;

%macro C_comp;
%if (&ss= c or &ss = e or &ss = r) %then %do;
  %let msgc=;
  %let emsgc=;
  %let msgc=Running comparison with last year;
  %DISPLAY Checks.msgc noinput;
  %include "&eusilc/pgm/Y1_comp_start.sas";  /* run program */
  %include "&eusilc/pgm/Y1_comp_discrete.sas";
  %include "&eusilc/pgm/Y1_comp_continuous.sas";	
  %include "&eusilc/pgm/Y1_comp_export.sas";
%end;
%mend C_comp;

%macro T_comp;
%if &Number_T= 1 %then %do;
  %let msgt=;
  %let emsgt=;
  %let msgt=Running comparison with last trasmission;
  %DISPLAY Checks.msgt noinput;
  %include "&eusilc/pgm/T1_compare.sas";  /* run program */
%end;
%else  %do;
/* no files available for the comparision */
		data NoError;
			N_trasmission  = 1;
			format label $char80.;
			label ="No sas datasets from previous versions available for the comparision";
		run;
		/* to create name file with date and time  */
		%let Time      = %sysfunc(time(),time8.0);
		%let Time_HH   = %scan(&Time.,1,:);
		%let Time_MM   = %scan(&Time.,2,:);
		%let Time_SS   = %scan(&Time.,3,:);
		%let Time_run=&Time_HH..&Time_MM..&Time_SS;
		%let dat_time=&sysdate._&Time_run;
		%let fname1='&eusilc/&cc/&ss&yy/&ss&cc&yy._With_previousTrasmission_.&dat_time..csv';
		proc export data=NoError  outfile="&fname1 "
			dbms=dlm   replace;
			delimiter=',';
		quit;
%end;
%mend T_comp;

%macro alll;
%init;
%if &ok1=1 %then %do;
	%if &load ne n %then %load;
	%chk1;
	%chk2;
	%l_wgt;
	%c_wgt;
	%analysis;
	%C_outliers;
	%C_comp;
	%T_comp;
	%end;
%DISPLAY Checks.end;
%mend alll;
%alll;

