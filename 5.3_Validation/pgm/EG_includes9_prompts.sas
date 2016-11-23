
options nonotes nosource nosource2 nomlogic nomprint nosymbolgen;

/*******************************************************************************************************************/
/*                                                                                                                 */
/* Name of the macro program: create_list                                                                          */
/* Subject           : Re-create the list of choices from the multiple choices prompt as it's done in SAS/EG 4.1   */
/*                                                                                                                 */
/* Parameters of the macro-program                                                                                 */
/* prompt_name       : Name of the prompt                                                                          */
/* ptype             : Type of the prompt --> string, interger, float, date, etc...                                */
/* penclose          : If the option 'Enclosed values with quotes' was selected in SAS/EG 4.1                      */
/* pmultipl          : If the prompt is a Multiple choices vprompt                                                 */
/* psepar            : specific separator, nothing if there is no specific separator, comma is the default         */
/*                                                                                                                 */
%macro local_or_server;
%if &sysscp = WIN %then %do ;
	            %let lst=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ;
	            %let start=%sysfunc(indexc(%sysfunc(compress(&lst)),A));
	            %let finish=%sysfunc(indexc(%sysfunc(compress(&lst)),Z));
            %do i = &start %to &finish;
		            %let drv = %scan(&lst,&i);
		            %if %sysevalf(%sysfunc(fileexist(&drv.:\main\pgm\create_list.sas))) 
                                  %then %do;
					                        %include "&drv.:\main\pgm\create_list.sas";
								        %end;
            %end;
                         %end;
%else %do; 
	        %include "/ec/prod/server/sas/0eusilc/main/pgm/create_list.sas";
	  %end;
%mend local_or_server;
%local_or_server;

%create_list(prompt_name=D_file,ptype=String,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=eDAMIS,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=errmax,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=nrow,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=FACTOR,ptype=float,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=H_file,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=hid,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=load,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=P_file,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=R_file,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=rate,ptype=float,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=RCC,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=RCL,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=RYYYY,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=SEL_RESP,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=th,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=thi,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=THRES,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=WW,ptype=integer,penclose=no,pmultipl=no,psepar=) ;																

/*                                                                                                                 */
/* End of the macro program: create_list                                                                           */
/*                                                                                                                 */
/*******************************************************************************************************************/


* INCLUDES9.SAS;

%let yy=%substr(&RYYYY,3,2);
%let ss=%lowcase(&RCL);
%put &yy;
/*--------------------------------------*/
*%let eusilc=/ec/prod/server/sas/0eusilc/main;

%let eusilc=/ec/prod/server/sas/0eusilc/main/test_reconcil;
options source nosource2 notes;

%let csv=&eusilc/params;


*** create parameter files ***; 
%MACRO frmts(f);
 
 
/*source file*/
filename parfile "&csv/checks 20&yy/_par&ss&yy._s.csv"; *** variables parameter file;  
/*output files*/
filename frmfile "&eusilc/pgm/&ss&yy&f.format.0sas";  *** definition of variable formats; 
filename varfile "&eusilc/pgm/&ss&yy&f.var.0sas";  *** definition of variables list; 

/* create format file &ss&yy&f.format.0sas */

DATA _null_;
  length vars $2000.;
  retain vars;
	/*input file*/
  infile parfile MISSOVER DSD LRECL=2048 firstobs=2 end=fin TERMSTR=CRLF;
	/*output file*/
	file frmfile;
  format varnam $8.;
  format vformat $8.;
  length txt $256.;
  input varnam req vformat;
  if lowcase(substr(varnam,1,1)) = "&f" 
  or (substr(varnam,1,2) = "MH" and "&f" = "h") 
  or (substr(varnam,1,2) = "MI" and "&f" = "h") then
  do; 
    txt = "format "||compress(varnam)||" "||substr(vformat,2)||";";
	put txt;
	if not req then 
	do;
		txt = compress(varnam)||" = .;";
	 	put txt;
	end;
  	vars = trim(vars) || " " || compress(varnam);
	if substr(vformat,1,1) = "f" then
	do;
	  txt = "format "||compress(varnam)||"_F 2.;";
	  put txt;
      if not req then 
	  do;
		txt = compress(varnam)||"_F = .;";
	 	put txt;
	  end;
      vars = trim(vars) || " " || compress(varnam)|| "_F";
	end;
	if substr(vformat,1,1) = "i" then
	do;
	  txt = "format "||compress(varnam)||"_F $12.;";
	  put txt;
      vars = trim(vars) || " " || compress(varnam)|| "_F";
	  txt = "format "||compress(varnam)||"_FF 2.;";
	  put txt;
	  txt = compress(varnam)||"_FF = .;";
	  put txt;
	  txt = "format "||compress(varnam)||"_I 9.5;";
	  put txt;
	  txt = compress(varnam)||"_I = .;";
	  put txt;
	  txt = "rename "||compress(varnam)||"_F = "||compress(varnam)||"_FI;";
	  put txt;
	  txt = "rename "||compress(varnam)||"_FF = "||compress(varnam)||"_F;";
	  put txt;
      if not req then 
	  do;
		txt = compress(varnam)||"_F = .;";
	 	put txt;
	  end;
	end;
  end;
  if fin then
  do;
    file varfile lrecl=2000;
    put "%nrstr(%let) vars=";
	put vars;
	put ";";
  end;
RUN;
%MEND frmts;

%MACRO sntx(f);
filename chkfile  "&eusilc/pgm/&ss&yy&f.chk.0sas" lrecl=310;
 

filename parfile "&csv/checks 20&yy/_par&ss&yy._s.csv"; *** variables parameter file;   

filename pl120r "&csv/checks 20&yy/_PL120_r.sql"; *** routing code PL120;

%if &f=d or &f=h %then %let id=HID;
%else %let id=PID;           

DATA _null_; 
  infile parfile MISSOVER DSD LRECL=2048 firstobs=2 end=fin TERMSTR=CRLF;
  format varnam $8.;
  format formt $8.;
  format minval $350.;
  format maxval $256.;
  format flag $256.;
  format conditio $100.;
  format disp $35.;
  format labl $200.;
  input varnam req formt minval maxval flag conditio disp labl;

  file chkfile;
  length txt1 $256;
  length txt2 $350;
  length txt2f $350;
  length txt3 $256;
  length txt30 $256;
  length txt4 $256;
  length txt5 $256;

  if _N_= 1 then do;
    put "PROC SQL;";
  	put "Create table &ss%nrstr(&cc).&yy&f as select * from dds.&ss%nrstr(&cc).&yy&f ;";
	put "QUIT;";
    put "*----------------------------------------------------------------;";
  end;

  if lowcase(substr(varnam,1,1)) = "&f" 
  or (substr(varnam,1,2) = "MH" and "&f" = "h") 
  or (substr(varnam,1,2) = "MI" and "&f" = "h") then
  do;
 txt7 = "time = &f.B010";
 txt8 = "data vToterr&f";
 txt9 = "set vToterr&f vsumx ";
 txt10 = "data FToterr&f";
 txt11 = "set FToterr&f fsumx ";
  txt12 = "data VFToterr&f";
 txt13 = "set VFToterr&f vfsumx ";
   txt14 = "data RToterr&f";
 txt15 = "set RToterr&f rsumx ";
  txt16 = "data MToterr&f";
 txt17 = "set MToterr&f Msumx ";
 

if maxval in ("country") then
    txt1 = "select &f.B010 ""Year"", &f.B030 ""&id"", "||trim(varnam)||" from &ss%nrstr(&cc).&yy&f";
  else if maxval in ("hid","pid") then
    txt1 = "select &f.B010 ""Year"", &f.B030 ""&id"", "||trim(varnam)||" from &ss%nrstr(&cc).&yy&f";
  else if substr(varnam,2,4) = "B010" then 
    txt1 = "select &f.B010 ""Year"", &f.B030 ""&id"" from &ss%nrstr(&cc).&yy&f";
  else 
    txt1 = "select &f.B010 ""Year"", &f.B030 ""&id"", "||trim(varnam)||", "||trim(varnam)||"_F from &ss%nrstr(&cc).&yy&f";
/* c:maxval="year", l:"B010" then maxval = also "year" for following tests */
  if maxval = "year" then 
    txt2 = "where "||trim(varnam)||" not = "||trim(minval);  
  else if substr(varnam,2,4) = "B010" then do;
    txt2 = "where ("||trim(varnam)||" not between "||trim(minval)||" and "||trim(maxval)||")";  
	maxval = "year";
	end;
  else if maxval = "country" then
    txt2 = "where "||trim(varnam)||" not = %nrstr(%upcase)(""%nrstr(&cc)"")";
  else if maxval = "hid" and "&ss" = "c" then
    txt2 = "where "||trim(varnam)||" not between 1 and 999999";  
  else if maxval = "hid" and ("&ss" = "l" or "&ss" = "r") then
    txt2 = "where "||trim(varnam)||" not between 100 and 99999999";  
  else if maxval = "pid" and "&ss" = "c" then
    txt2 = "where "||trim(varnam)||" not between 101 and 99999999";                        
  else if maxval = "pid" and ("&ss" = "l" or "&ss" = "r") then
    txt2 = "where "||trim(varnam)||" not between 10001 and 9999999999";
  else if maxval = "c_pid" and ("&ss" = "l" or "&ss" = "r") then do;
 	txt2 = "where "||trim(varnam)||" > 99999999 or ("||trim(varnam)||"> 0 and "||trim(varnam)||" < 101)";
	txt2f = "where ("||trim(varnam)||"_F not in "||trim(flag)||")";
	txt3 = "where ("||trim(varnam)||" not = . and "||trim(varnam)||"_F ne . and "||trim(varnam)||"_F < 0) or ("||trim(varnam)||" = . and "||trim(varnam)||"_F ge 0)";
  end; 
  else if maxval = "nuts" then do;
    txt2 = "where (not exists (select nutscode from nuts where "||trim(varnam)||" =nutscode) and "||trim(varnam)||" not = """")";       
    txt2f = "where ("||trim(varnam)||"_F not in "||trim(flag)||")";
    txt3 = "where ("||trim(varnam)||" not = """" and "||trim(varnam)||"_F ne . and "||trim(varnam)||"_F < 0) or ("||trim(varnam)||" = """" and "||trim(varnam)||"_F ge 0)";
    end;  
  else if maxval = "list" then
    if index(formt,"$") then do;
      txt2 = "where ("||trim(varnam)||" not in "||trim(minval)||" and "||trim(varnam)||" not = """")";
      txt2f = "where ("||trim(varnam)||"_F not in "||trim(flag)||")";
      txt20f = "and ("||trim(varnam)||"_F not = .)";
      txt3 = "where ("||trim(varnam)||" not = """" and "||trim(varnam)||"_F ne . and "||trim(varnam)||"_F < 0) or ("||trim(varnam)||" = """" and "||trim(varnam)||"_F ge 0)";
      end;
    else do;
      txt2 = "where ("||trim(varnam)||" not in "||trim(minval)||" and "||trim(varnam)||" not = .)";
      txt2f = "where ("||trim(varnam)||"_F not in "||trim(flag)||")";
      txt20f = "and ("||trim(varnam)||"_F not = .)";
      txt3 = "where ("||trim(varnam)||" not = . and "||trim(varnam)||"_F ne . and "||trim(varnam)||"_F < 0) or ("||trim(varnam)||" = . and "||trim(varnam)||"_F ge 0)";
      end;
  else do;
      txt2 = "where ("||trim(varnam)||" not between "||trim(minval)||" and "||trim(maxval)||" and "||trim(varnam)||" not = .)";
      txt2f = "where ("||trim(varnam)||"_F not in "||trim(flag)||")";
      txt20f = "and ("||trim(varnam)||"_F not = .)";
      txt3 = "where ("||trim(varnam)||" not = . and "||trim(varnam)||"_F ne . and "||trim(varnam)||"_F < 0) or ("||trim(varnam)||" = . and "||trim(varnam)||"_F ge 0)";
      txt30 = " or ("||trim(varnam)||" not = 0 and "||trim(varnam)||"_F = 0) or ("||trim(varnam)||" = 0 and "||trim(varnam)||"_F ne 0)";
      end;
  if conditio not = "" then do;
    txt4 = "select &f.B010 ""Year"", &f.B030 ""&id"", "||trim(varnam)||", "||trim(varnam)||"_F, "||trim(disp)||" from dds.&ss%nrstr(&cc).&yy&f";
    txt5 = "where "||trim(varnam)||"_F ne -3 and (("||trim(conditio)||" and "||trim(varnam)||"_F ne -2) or not ("||trim(conditio)||" or "||trim(varnam)||"_F ne -2))";
    end;

  put "title5;";
  put "title3 '%upcase(" varnam ")- " labl "';";
  put "title4 'Syntax check: invalid values';";
  put "PROC SQL;";
  put "Create table tempo as";
  put txt1;
  put txt2;
 /* put "order by &f.B030,&f.B010;";*/
   put "order by &f.B010,&f.B030;";
put "quit;";
put "proc sort data=tempo;";
put "by &f.B010;";
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 put "by   &f.B010;";
 put "cnt +1;";
put "if first.&f.b010 then cnt=1;";
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";

put "proc sql;";
 put "Select * from tempoxx(obs=%nrstr(&errmax) )";
  put "order by &f.B010 desc,&f.B030;";  
put "quit;";
put "proc sql;";
  put "Insert into errtab&f set varnam = '" varnam "', vval = 1, error = (select count(*) from tempo);";
  put "QUIT;";

/* added  values datsets error by years AND For VALUE ERRORS*/
   put " data verror1 (keep=varnam time );";
 put "set tempo; ";
 put "varnam = '" varnam "';";
 put txt7;
 put ";";
 put "run;";
 
put "PROC SQL;";
 put "Create table Vsum1 as ";
put 'select varnam , time, count(*) as Tyear from verror1';
put "group by varnam, time;";
	put "QUIT;";

put "proc transpose data=vsum1 out=vsumx prefix=Y_;";
   put" by varnam ;";
   put " id time;";
   put " var Tyear;";
put "run;";
put 'data vsumx;';
	put "set vsumx;";
	put "drop _NAME_; ";
put "run;";
put txt8;
 put ";";
 put txt9;
 put ";";
put "run;";
/*end*/

  put " ";
  if maxval not in ("year","country","hid","pid") then do;
    put "title4 'Syntax check: invalid flags';";
    put "PROC SQL;";
    put "Create table tempo as";
    put txt1;
    put txt2f;
	if not req then put txt20f;
    put "order by &f.B010,&f.B030;";
    put "quit;";
	put "proc sort data=tempo;";
put "by &f.B010;";
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 put "by   &f.B010;";
 put "cnt +1;";
put "if first.&f.b010 then cnt=1;";
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";

put "proc sql;";
 put "Select * from tempoxx(obs=%nrstr(&errmax) )";
  put "order by &f.B010 desc,&f.B030;";  
put "quit;";
put "proc sql;";

     put "Insert into errtab&f set varnam = '" varnam "', fval = 1, error = (select count(*) from tempo);";
    put "QUIT;";
    put " ";
/* added   datsets error by years AND For flags  ERRORS*/
   put " data verror1 (keep=varnam time );";
 put "set tempo; ";
 put "varnam = '" varnam "';";
 put txt7;
 put ";";
 put "run;";
 
put "PROC SQL;";
 put "Create table fsum1 as ";
put 'select varnam , time, count(*) as Tyear from verror1';
put "group by varnam, time;";
	put "QUIT;";

put "proc transpose data=fsum1 out=fsumx prefix=Y_;";
   put" by varnam ;";
   put " id time;";
   put " var Tyear;";
put "run;";
put 'data fsumx;';
	put "set fsumx;";
	put "drop _NAME_; ";
put "run;";
put txt10;
 put ";";
 put txt11;
 put ";";
put "run;";

    put "title4 'Syntax check: value and flag incompatible';";
    put "PROC SQL;";
    put "Create table tempo as";
    put txt1;
    put txt3;
	if upcase(substr(varnam,2,1)) = "Y" then put txt30;
    put "order by &f.B010,&f.B030;";
  put "quit;";
  put "proc sort data=tempo;";
put "by &f.B010;";
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 put "by   &f.B010;";
 put "cnt +1;";
put "if first.&f.b010 then cnt=1;";
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";

put "proc sql;";
 put "Select * from tempoxx(obs=%nrstr(&errmax) )";
  put "order by &f.B010 desc,&f.B030;";  
put "quit;";
put "proc sql;";
    put "Insert into errtab&f set varnam = '" varnam "', flag = 1, error = (select count(*) from tempo);";
    put "QUIT;";
    put " ";
/* added  values datsets error by years AND For VALUE ANS fLAG ERRORS*/
 put " data verror1 (keep=varnam time );";
 put "set tempo; ";
 put "varnam = '" varnam "';";
 put txt7;
 put ";";
 put "run;";
 
put "PROC SQL;";
 put "Create table Vfsum1 as ";
put 'select varnam , time, count(*) as Tyear from verror1';
put "group by varnam, time;";
	put "QUIT;";

put "proc transpose data=vfsum1 out=vfsumx prefix=Y_;";
   put" by varnam ;";
   put " id time;";
   put " var Tyear;";
put "run;";
put 'data vfsumx;';
	put "set vfsumx;";
	put "drop _NAME_; ";
put "run;";
put txt12;
 put ";";
 put txt13;
 put ";";
put "run;";
    end;

  if conditio not = "" and req then do;
  if varnam = "PL120" then do;
  	%include pl120r;
  end;
  else do;	
  	if length(conditio) > 32 then do;
	  conditio2 = substr(conditio,25);
	  sp = index(conditio2,' ');
	  conditio2 = substr(conditio2,sp+1);
	  conditio = substr(conditio,1,24+sp);
    put "title4 'Routing check: flag value must be -2 (only) if " conditio "';";
    put "title5 '" conditio2 "';";
    end;
    else put "title4 'Routing check: flag value must be -2 (only) if " conditio "';";
    put "PROC SQL;";
    put "Create table tempo as";
    put txt4;
    put txt5;
    put "order by &f.B010 desc,&f.B030;";
 put "quit;";
 put "proc sort data=tempo;";
put "by &f.B010;";
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 put "by   &f.B010;";
 put "cnt +1;";
put "if first.&f.b010 then cnt=1;";
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";

put "proc sql;";
 put "Select * from tempoxx(obs=%nrstr(&errmax) )";
  put "order by &f.B010 desc,&f.B030;";  
put "quit;";
put "proc sql;";
    put "Insert into errtab&f set varnam = '" varnam "', routing = 1, error = (select count(*) from tempo);";
    put "QUIT;";
    put " ";
	end;
/* added  values datsets error by years AND For ROUTING ERRORS*/
 put " data verror1 (keep=varnam time );";
 put "set tempo; ";
 put "varnam = '" varnam "';";
 put txt7;
 put ";";
 put "run;";
 
put "PROC SQL;";
 put "Create table Rsum1 as ";
put 'select varnam , time, count(*) as Tyear from verror1';
put "group by varnam, time;";
	put "QUIT;";

put "proc transpose data=rsum1 out=rsumx prefix=Y_;";
   put" by varnam ;";
   put " id time;";
   put " var Tyear;";
put "run;";
put 'data rsumx;';
	put "set rsumx;";
	put "drop _NAME_; ";
put "run;";
put txt14;
 put ";";
 put txt15;
 put ";";
put "run;";

    end;

  if /*&yy>07 and*/ index(flag,"-1") then do;
    if substr(varnam,2,1) = "Y" then vpc = 2;
	else vpc = 5;
	put "title4 'Missing values check: over " vpc "% of missing values ! ';";
    put "PROC SQL;";
	txt1 = "CREATE TABLE tempo00 AS SELECT &f.B010, (CASE WHEN "||trim(varnam)||"_F = -1 THEN 0 WHEN "||trim(varnam)||"_F >= 0 THEN 1 END ) AS calcmiss  from &ss%nrstr(&cc).&yy&f ORDER BY &f.B010;";
	put txt1;
    put "QUIT;";

	put "PROC FREQ DATA=tempo00 noprint; TABLES calcmiss / NOCUM OUT=tempo0; BY &f.B010; RUN;";

    put "PROC SQL;";
	put "Create table tempo as";
	put "select &f.B010 ""Year"", count ""N missing"", percent ""% of missing values"" format=3.0";
	put "FROM tempo0";
	put "where percent > " vpc " and calcmiss = 0";
    put "order by &f.B010;";
 put "quit;";
 put "proc sort data=tempo;";
put "by &f.B010;";
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 put "by   &f.B010;";
 put "cnt +1;";
put "if first.&f.b010 then cnt=1;";
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";

put "proc sql;";
 put "Select * from tempoxx(obs=%nrstr(&errmax) )";
  put "order by &f.B010 desc;";  
put "quit;";
put "proc sql;";;  
    put "Insert into errtab&f set varnam = '" varnam "',missng = 1, error = (select max(percent) from tempo);";
    put "QUIT;";

/* added  values datsets error by years AND For MISSING  ERRORS*/
 
 put " data Msum1 (keep=varnam time tyear);";
 put "set tempo; ";
 put "varnam = '" varnam "';";
 put txt7;
 put ";";
 put "tyear=count;";
 put "run;";
put "proc transpose data=Msum1 out=Msumx prefix=Y_;";
   put" by varnam ;";
   put " id time;";
   put " var Tyear;";
put "run;";
put 'data Msumx;';
	put "set Msumx;";
	put "drop _NAME_; ";
put "run;";
put txt16;
 put ";";
 put txt17;
 put ";";
put "run;";

  end;	
put "*----------------------------------------------------------------;";
end;
RUN;
%MEND sntx;


%MACRO lgcl;
filename chkplist "&eusilc/pgm/&ss&yy.chkl.0sas" ;         *** macros to run with params;
 


filename parpfile "&csv/checks 20&yy/_par&ss&yy._l.csv";   *** checks definitions;   

filename l128 "&csv/checks 20&yy/_L128.sql"; ***  code #128;
filename l135 "&csv/checks 20&yy/_L135.sql"; ***  code #135;


DATA _null_; 
  infile parpfile MISSOVER DSD LRECL=2048 firstobs=2 ;
  format cod 3.;
  format tit $200.;
  format tit2 $120.;
  format sel $200.;
  format fr $1.;
  format jn $1.;
  format on $100.;
  format wher $350.;
  format gr $30.;
  format hav $250.;
  input cod tit sel fr jn on wher gr hav;

  file chkplist;
    length txt1 $350;
    length txt2 $350;
    length txt3 $350;
    length txt4 $256;

  if _N_= 1 then do;
    put "PROC SQL;";
  	put "Create table &ss%nrstr(&cc).&yy.d as select * from dds.&ss%nrstr(&cc).&yy.d ;";
  	put "Create table &ss%nrstr(&cc).&yy.r as select * from dds.&ss%nrstr(&cc).&yy.r ;";
  	put "Create table &ss%nrstr(&cc).&yy.h as select * from dds.&ss%nrstr(&cc).&yy.h ;";
  	put "Create table &ss%nrstr(&cc).&yy.p as select * from dds.&ss%nrstr(&cc).&yy.p ;";
	put "QUIT;";
	put "*----------------------------------------------------------------;";
  end;

	txt1 = "select "||trim(sel)||" from &ss%nrstr(&cc).&yy"||fr||" as a";
	if jn ne ""  then
	  txt2 = "left join &ss%nrstr(&cc).&yy"||jn||" as b on "||trim(on);
	if wher ne "" then
	  txt3 = "where "||trim (wher);
	if gr ne "" then
	  txt4 = "group by "||trim(gr)||" having "||trim(hav);
   /* txt5 = "order by "||scan(sel,2,",")||","||scan(sel,1,",");*/
	/*txt5 = "order by "||scan(sel,1,",")||","||scan(sel,2,",")|| desc"; */
		txt5 = "order by "||scan(sel,1,",")||" desc,"||scan(sel,2,",");
    txt6 = "time ="||fr||"b010"||";";
    txt7 = "by "||fr||"b010"||";";
	    txt8= "if first."||fr||"b010 then cnt=1;"; 
	if length(tit) > 120 then do;
	  tit2 = substr(tit,100);
	  sp = index(tit2,' ');
	  tit2 = substr(tit2,sp+1);
	  tit = substr(tit,1,100+sp);
    end;
    else tit2 = "";

	if cod = 128 then do;
  		%include l128;
  	end;
	else if cod = 135 then do;
  		%include l135;
  	end;
	else do;
	    put 'title1 "Check #' cod '/ &datum";';
		put 'title2 "&ccnam - &surtyp survey &suryear";';
	    put 'title3 "' tit '";';
	    if tit2 ne "" then put 'title4 "' tit2 '";';

	    put "PROC SQL;";
		put "Create table tempo as";
		put txt1;
		if txt2 ne "" then put txt2;
		if txt3 ne "" then put txt3;
		if txt4 ne "" then put txt4;
	    put ";";
		put "quit;";
put "proc sort data=tempo;";
put txt7;
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 
put txt7;
 put "cnt +1;";
/* put "if first.&f.b010 then cnt=1;"; */
put txt8;
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";

put "proc sql;";
	put "Select * from tempoxx (obs=%nrstr(&errmax)) as a ";
	%if &ss=l %then put txt5;;
   		*put txt5;
	    put ";";
put "quit;";

put "proc sql;";
	put 'Insert into errtabl set cod = ' cod ', error = (select count(*) from tempo);';

		put "QUIT;";

 put " data error1 (keep=cod time );";
 put "set tempo; ";
 put ' cod = ' cod' ;';
 put txt6;
 put "run;";
 
put "PROC SQL;";
 put "Create table sum1 as ";
put 'select cod , time, count(*) as Tyear from error1';
put "group by cod, time;";
	put "QUIT;";

put "proc transpose data=sum1 out=sumx prefix=Y_;";
   put" by cod ;";
   put " id time;";
   put " var Tyear;";
put "run;";
put 'data sumx;';
	put "set sumx;";
	put "drop _NAME_; ";
put "run;";
put "data Toterr;";
	put 'set Toterr sumx ;';
put "run;";

 	end;
	put "*----------------------------------------------------------------;";
RUN;
%MEND lgcl;

%frmts(d);
%frmts(r);
%frmts(h);
%frmts(p);
%sntx(d);
%sntx(r);
%sntx(h);
%sntx(p);
%lgcl;
