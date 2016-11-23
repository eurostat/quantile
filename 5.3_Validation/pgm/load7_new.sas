* LOAD7.SAS;

* load data;

filename frmfile "&eusilc/pgm/&ss&yy&f.format.0sas";  *** definition of variable formats; 
filename inpfile "&eusilc/&cc/tmp/input.tmp";   *** temporary file with input variables;
%include "&eusilc/pgm/&ss&yy&f.var.0sas" /lrecl=2000;  *** definition of variables list; 



%MACRO mload;

/* step  to made  a copy of the last trasmission*/

	%if %SYSFUNC(EXIST(dds.&ss&cc&yy.&f)) %then
		%do;
			data back.&ss&cc&yy.&f;
				set dds.&ss&cc&yy.&f;
			run;
				data &F.test; set back.&ss&cc&yy.&f;run;
			%let Number_T=1;
		%end;
	%else
		%do;
			data DataNotExist;
				N_file="&f";
				country="&cc";
				year="&RYYYY";
			run;
			%if not %sysfunc(exist(Countryfile)) %then
				%do;
					data Countryfile;
						set DataNotExist;
					run;
				%end;
			%else
				%do;
					data Countryfile;
						set Countryfile DataNotExist;
					run;
				%end;
		%end;
  

*** create temporary files ***; 

DATA _null_;
  %if %SYSEVALF(&sysver > 9) %then infile &f.file MISSOVER DSD LRECL=32767 firstobs=1 obs=1 TERMSTR=&del;
  %else infile &f.file MISSOVER DSD LRECL=2048 firstobs=1 obs=1;;

  file inpfile;
  input (varn1-varn350) ($) linesize=300;  /* varn250 => varn280 for X10 */ /* changed 10/06/2015*/
  array vars(*) $8 varn1--varn350; /* varn250 => varn280 for X10 */

  do i = 1 to dim(vars);
 *	if substr(upcase(vars(i)),1,1) in ("D","H","R","P") then put vars(i);
 	put vars(i);
  end;
RUN;

*** load data ***; 

  PROC PRINTTO log=report;
  RUN;
  	%put  ;
	%put ==================================;
	%put &f.-file (load csv to SAS dataset);
	%put ==================================;
	option notes;

DATA dds.&ss&cc&yy&f (drop= LEN varx varrest);
  length txt $200;  
  retain missid 0 f_b020 0 f_db040 0 f_pb210 0 f_pb220a 0 f_pb220b 0 f_db090 0 f_rb050 0 f_pb040 0 f_pb060 0; 
  %if %SYSEVALF(&sysver > 9) %then infile &f.file MISSOVER DSD LRECL=2048 firstobs=2 end=fin TERMSTR=CRLF;
  %else infile &f.file MISSOVER DSD LRECL=2048 firstobs=2 end=fin;;
  %include frmfile;
  input %include inpfile;;

  if &f.B030 = . then missid = missid + 1;
  if fin and missid > 0 then do;
  	txt = "----> "||trim(put(missid,best6.))||" records with missing ID numbers in infile!";
	put "----> ";
	put txt;
  end;
  if &f.B030 = . then delete;

  /* change in DB020 RB020 HB020 PB020*/

	len = LENGTH(&f.B020); 
	if len =2 and &f.B020="GR" then do;
		&f.B020="EL";
		f_b020 = f_b020 +1;
	end;
	IF len >2 and substr(&f.B020,1, 2)= "GR" then do;
   		varx="EL";
		f_b020= f_b020 +1;
   		varrest=substr(&f.B020,3,len);
   		&f.B020=cats(varx, varrest); 
	end; 

	/* change in DB040*/

	%if &f=d %then %do;
		len = LENGTH(DB040); 
		if len =2 and DB040="GR" then do;
			DB040="EL";
			f_db040 = f_db040 +1;
		end;
		IF len >2 and substr(DB040,1, 2)= "GR" then do;
   			varx="EL";
			f_db040 = f_db040 +1;
   			varrest=substr(DB040,3);
   			DB040=cats(varx, varrest); 
		end; 
	%end;

	/* change in PB210*/
	%if &f=p and (&ss=c or &ss=r) %then %do;
		len = LENGTH(PB210); 
		if len =2 and PB210="GR" then do;
			PB210="EL";
			f_pb210 = f_pb210 +1;
		end;
		IF len >2 and substr(PB210,1, 2)= "GR" then do;
   			varx="EL";
			f_pb210= f_pb210 +1;
   			varrest=substr(PB210,3);
   			PB210=cats(varx, varrest); 
		end; 
	%end;
	/* change in PB220A*/
	%if &f=p and (&ss=c or &ss=r) %then %do;
		len = LENGTH(PB220A); 
		if len =2 and PB220A="GR" then do;
			PB220A="EL";
			f_pb220a = f_pb220a +1;
		end;
		IF len >2 and substr(PB220A,1, 2)= "GR" then do;
   			varx="EL";
			f_pb220a = f_pb220a +1;
   			varrest=substr(PB220A,3);
   			PB220A=cats(varx, varrest); 
		end; 
	%end;
	/* change in PB220B*/
	%if &f=p and (&ss=c or &ss=r) %then %do;
		len = LENGTH(PB220B); 
		if len =2 and PB220B="GR" then do;
			PB220B="EL";
			f_pb220b = f_pb220b +1;
		end;
		IF len >2 and substr(PB220B,1, 2)= "GR" then do;
   			varx="EL";
			f_pb220b = f_pb220b +1;
   			varrest=substr(PB220B,3);
   			PB220B=cats(varx, varrest); 
		end; 
	%end;

	/* check if DB090 filled not only in last year*/
	%if &f=d and &ss=r %then %do;	
		if (DB090 ne . and DB010 ne &RYYYY) then do;
			f_db090 = f_db090 +1;
		end;	
	%end;

	/* check if RB050 filled not only in last year*/
	%if &f=r and &ss=r %then %do;	
		if (RB050 ne . and RB010 ne &RYYYY) then do;
			f_rb050 = f_rb050 +1;
		end;	
	%end;

	/* check if PB040 filled not only in last year*/
	%if &f=p and &ss=r %then %do;	
		if (PB040 ne . and PB010 ne &RYYYY) then do;
			f_pb040 = f_pb040 +1;
		end;	
	%end;

	/* check if PB060 filled not only in last year*/
	%if &f=p and &ss=r %then %do;	
		if (PB060 ne . and PB010 ne &RYYYY) then do;
			f_pb060 = f_pb060 +1;
		end;	
	%end;

if fin and f_b020 > 0 then do;
  	txt = "----> "||trim(put(f_b020,best6.))||" records with GR instead of EL in &f.B020";
	put "----> ";
	put txt;
end;
if fin and f_db040 > 0 then do;
  	txt = "----> "||trim(put(f_db040,best6.))||" records with GR instead of EL in DB040";
	put "----> ";
	put txt;
end;
if fin and f_pb210 > 0 then do;
  	txt = "----> "||trim(put(f_pb210,best6.))||" records with GR instead of EL in PB210";
	put "----> ";
	put txt;
end;
if fin and f_pb220a > 0 then do;
  	txt = "----> "||trim(put(f_pb220a,best6.))||" records with GR instead of EL in PB220a";
	put "----> ";
	put txt;
end;
if fin and f_pb220b > 0 then do;
  	txt = "----> "||trim(put(f_pb220b,best6.))||" records with GR instead of EL in PB220b";
	put "----> ";
	put txt;
end;
if fin and f_db090 > 0 then do;
  	txt = "----> "||trim(put(f_db090,best6.))||" records from previous years with values in DB090";
	put "----> ";
	put txt;
	put "----> ";
end;
if fin and f_rb050 > 0 then do;
  	txt = "----> "||trim(put(f_rb050,best6.))||" records from previous years with values in RB050";
	put "----> ";
	put txt;
	put "----> ";
end;
if fin and f_pb040 > 0 then do;
  	txt = "----> "||trim(put(f_pb040,best6.))||" records from previous years with values in PB040";
	put "----> ";
	put txt;
	put "----> ";
end;
if fin and f_pb060 > 0 then do;
  	txt = "----> "||trim(put(f_pb060,best6.))||" records from previous years with values in PB060";
	put "----> ";
	put txt;
	put "----> ";
end;
  drop txt missid f_b020 f_db040 f_pb210 f_pb220a f_pb220b f_db090 f_rb050 f_pb040 f_pb060;
RUN;

	option nonotes; 

DATA _null_;
 	infile inpfile;
	length vars $2000;
	length var $8;
	length txt $80;
	vars = symget("vars");
	input var;
	if index(vars,upcase(trim(var))) = 0 then
	do;
	  txt = "***** "|| trim(var) || " found in input data, but not in variable list";
	  put txt;
	end;
RUN;


PROC PRINTTO;
RUN;

%mend;

%mload;


*** create suppl. variables, split imputation factor ***; 

%MACRO SUPVAR;
%if &f=r and &ss=c %then
%do;
  DATA dds.&ss&cc&yy&f;                               
   set dds.&ss&cc&yy&f;
	if RB080_F = 1 then age = RB010 - RB080 - 1;
	RHID = int(rb030/100); 
  RUN;
%end;

%if &f=r and (&ss=l or &ss=r or &ss=e)%then
%do;
  DATA dds.&ss&cc&yy&f;                               
    set dds.&ss&cc&yy&f;
	if RB080_F = 1 then age = RB010 - RB080 - 1;
	RHID = rb040; 
  RUN;
%end;

%if &f=h and (&ss=c or &ss=l  or &ss=r) %then %do;
	%let avfin=HY040N_FI HY050N_FI HY060N_FI HY070N_FI HY080N_FI HY081N_FI HY090N_FI HY110N_FI HY130N_FI HY131N_FI HY170N_FI;
	%let avfn=HY040N_F HY050N_F HY060N_F HY070N_F HY080N_F HY081N_F HY090N_F HY110N_F HY130N_F HY131N_F HY170N_F;
	%let avin=HY040N_I HY050N_I HY060N_I HY070N_I HY080N_I HY081N_I HY090N_I HY110N_I HY130N_I HY131N_I HY170N_I;
	%let avfig=HY100N_FI HY120N_FI HY140N_FI HY145N_FI HY040G_FI HY050G_FI HY060G_FI HY070G_FI HY080G_FI HY081G_FI HY090G_FI HY100G_FI HY110G_FI HY120G_FI HY130G_FI HY131G_FI HY140G_FI HY170G_FI;
	%let avfg=HY100N_F HY120N_F HY140N_F HY145N_F HY040G_F HY050G_F HY060G_F HY070G_F HY080G_F HY081G_F HY090G_F HY100G_F HY110G_F HY120G_F HY130G_F HY131G_F HY140G_F HY170G_F;
	%let avig=HY100N_I HY120N_I HY140N_I HY145N_I HY040G_I HY050G_I HY060G_I HY070G_I HY080G_I HY081G_I HY090G_I HY100G_I HY110G_I HY120G_I HY130G_I HY131G_I HY140G_I HY170G_I;

	DATA &ss&cc&yy&f.0;                               
	    set dds.&ss&cc&yy&f;
		* split flags and imputation factor;
	    array nfi (*) &avfin;
	    array nf (*) &avfn;
	    array ni (*) &avin;
	    do i = 1 to dim(nfi);
			if substr(nfi(i),1,1) in ("-","0") then do;
			nf(i) = nfi(i);
			ni(i) = .;
			end;
		else do;
			nf(i) = substr(nfi(i),1,2);
			ni(i) = substr(nfi(i),3);
			end;
	    end;

	    array gfi (*) HY010_FI HY020_FI HY022_FI HY023_FI &avfig;
	    array gf (*) HY010_F HY020_F HY022_F HY023_F &avfg;
	    array gi (*) HY010_I HY020_I HY022_I HY023_I &avig;

		do i = 1 to dim(gfi);
			if substr(gfi(i),1,1) in ("-","0") then do;
			gf(i) = gfi(i);
			gi(i) = .;
			end;
		else do;
			gf(i) = substr(gfi(i),1,1);
			gi(i) = substr(gfi(i),2);
			end;
	    end;

	    drop &avfin HY010_FI HY020_FI HY022_FI HY023_FI &avfig; 

	    IF HB010 < 2007 then do;
				* If net and gross are given, take only gross to sum income;
				array hinc(*) HY030 HY040 HY050 HY060 HY070 HY080 HY090 HY100 HY110 HY120 HY130;
				array hnet(*) HY030N HY040N HY050N HY060N HY070N HY080N HY090N
			                      HY100N HY110N HY120N HY130N;
				array hgro(*) HY030G HY040G HY050G HY060G HY070G HY080G HY090G 
			                      HY100G HY110G HY120G HY130G;
				do i = 1 to dim(hgro);
				  if hgro(i) not in (0,.) then hinc(i) = hgro(i);
				  else if hnet(i) not in (0,.) then hinc(i) = hnet(i);
				  else  hinc(i) = 0;
				end;

				if HY140G not in (0,.) then HY140 = HY140G;
				else if sum(HY140N,HY145N,0) not in (0,.) then HY140 = sum(HY140N,HY145N,0);
				else  HY140 = 0;

				drop i;

				* income totals;

				  HGROINC = sum(HY040G,HY050G,HY060G,HY070G,HY080G,HY090G,HY110G,0);  *total gross;
			      HNINCS = sum(HY050,HY060,HY070,0);	                              *social benefits;	
				  HNETINC = sum(HY040,HNINCS,HY080,HY090,HY110,0) 
			             		 - sum(HY120,HY130,HY140,0);                   *total net;
				drop HY030--HY140;
		 end;

		 else do;
				* take only gross to sum income;
				* income totals;
				  HGROINC = sum(HY040G,HY050G,HY060G,HY070G,HY080G,HY090G,HY110G,0);  *total gross;
			        HNINCS = sum(HY050G,HY060G,HY070G,0);	                              *social benefits;	
		 		  HNETINC = HGROINC - sum(HY120G,HY130G,HY140G,0);  *total to calculate net;
		 end;

	  RUN;

%end;

%if &f=p and (&ss=c or &ss=l  or &ss=r) %then %do;

	%if &ss=c %then %let yy2=9999;
	%let avfin=PY010N_FI PY020N_FI PY021N_FI PY050N_FI PY070N_FI PY080N_FI PY090N_FI PY100N_FI PY110N_FI PY120N_FI PY130N_FI PY140N_FI;
	%let avfn=PY010N_F PY020N_F PY021N_F PY050N_F PY070N_F PY080N_F PY090N_F PY100N_F PY110N_F PY120N_F PY130N_F PY140N_F;
	%let avin=PY010N_I PY020N_I PY021N_I PY050N_I PY070N_I PY080N_I PY090N_I PY100N_I PY110N_I PY120N_I PY130N_I PY140N_I;
	%let avfig=PY035N_FI PY010G_FI PY020G_FI PY021G_FI PY030G_FI PY031G_FI PY035G_FI PY050G_FI PY070G_FI PY080G_FI PY090G_FI PY100G_FI PY110G_FI PY120G_FI PY130G_FI PY140G_FI PY200G_FI;
	%let avfg=PY035N_F PY010G_F PY020G_F PY021G_F PY030G_F PY031G_F PY035G_F PY050G_F PY070G_F PY080G_F PY090G_F PY100G_F PY110G_F PY120G_F PY130G_F PY140G_F PY200G_F;
	%let avig=PY035N_I PY010G_I PY020G_I PY021G_I PY030G_I PY031G_I PY035G_I PY050G_I PY070G_I PY080G_I PY090G_I PY100G_I PY110G_I PY120G_I PY130G_I PY140G_I PY200G_I;

	  DATA &ss&cc&yy&f.0;                               
	    set dds.&ss&cc&yy&f;
		* split flags and imputation factor;
	    array nfi (*) &avfin;
	    array nf (*) &avfn;
	    array ni (*) &avin;

	do i = 1 to dim(nfi);
			if substr(nfi(i),1,1) in ("-","0") then do;
			nf(i) = nfi(i);
			ni(i) = .;
			end;
		else do;
			nf(i) = substr(nfi(i),1,2);
			ni(i) = substr(nfi(i),3);
			end;
	    end;

	    array gfi (*) &avfig;
	    array gf (*) &avfg;
	    array gi (*) &avig;

		do i = 1 to dim(gfi);
			if substr(gfi(i),1,1) in ("-","0") then do;
			gf(i) = gfi(i);
			gi(i) = .;
			end;
		else do;
			gf(i) = substr(gfi(i),1,1);
			gi(i) = substr(gfi(i),2);
			end;
	    end;

	    drop &avfin &avfig; 

		If PB010 < 2007 then do;
				* If net and gross are given, take only gross to sum income;	
				array pinc(*) PY010 PY020 PY021 PY035 PY050 PY070 PY080 PY090
			                      PY100 PY110 PY120 PY130 PY140;
				array pnet(*) PY010N PY020N PY021N PY035N PY050N PY070N PY080N PY090N
			                      PY100N PY110N PY120N PY130N PY140N;
				array pgro(*) PY010G PY020G PY021G PY035G PY050G PY070G PY080G PY090G
			                      PY100G PY110G PY120G PY130G PY140G;

					do i = 1 to dim(pgro);
					  if pgro(i) not in (0,.) then pinc(i) = pgro(i);
					  else if pnet(i) not in (0,.) then pinc(i) = pnet(i);
					  else pinc(i) = 0;
					end;
				drop i;

				* income totals;
			IF &yy2 ge 2007 then do;
				X020G = PY020G;
				PY020G = PY021G;
				PY020 = PY021;
			end;

			 PGROINC = sum(PY010G,PY020G,PY050G,PY090G,PY100G,PY110G,PY120G,PY130G,PY140G,0);   *total gross; 
			 PNINCS = sum(PY090,PY120,PY130,PY140,0);    *social benefits without old-age;		
			 PNINCP = sum(PY100,PY110,0);		          *old-age;
			 PNETINC = sum(PY010,PY020,PY050,PNINCS,PNINCP,0); *total net;

			IF &yy2 ge 2007 then do;
				PY020G = X020G;
			end;
	 
			drop PY010--PY140 X020G;
		end;

		else if PB010 = 2007 and "&ss" = "c" then do;
			* take only gross to sum income;	
			* income totals;
		 	  PGROINC = sum(PY010G,PY021G,PY050G,PY080G,PY090G,PY100G,PY110G,PY120G,PY130G,PY140G,0);   *total gross; 
			  PNINCS = sum(PY090G,PY120G,PY130G,PY140G,0);    *social benefits without old-age;		
			  PNINCP = sum(PY100G,PY110G,0);		          *old-age;
			  PNETINC = PGROINC; *total to calculate net;
	    end;

		else if PB010 > 2007 and PB010 < 2011 then do;
			* take only gross to sum income;	
			* income totals;
		 	  PGROINC = sum(PY010G,PY021G,PY050G,PY090G,PY100G,PY110G,PY120G,PY130G,PY140G,0);   *total gross; 
			  PNINCS = sum(PY090G,PY120G,PY130G,PY140G,0);    *social benefits without old-age;		
			  PNINCP = sum(PY100G,PY110G,0);		          *old-age;
			  PNETINC = PGROINC; *total to calculate net;
		end;

		else do; /* add PY080G in sum of income components*/
			* take only gross to sum income;	
			* income totals;
		 	  PGROINC = sum(PY010G,PY021G,PY050G,PY080G,PY090G,PY100G,PY110G,PY120G,PY130G,PY140G,0);   *total gross; 
			  PNINCS = sum(PY090G,PY120G,PY130G,PY140G,0);    *social benefits without old-age;		
			  PNINCP = sum(PY100G,PY110G,0);		          *old-age;
			  PNETINC = PGROINC; *total to calculate net;
		end;

	 if "&ss" = "l" or "&ss" = "r" then do;

		if PB010 < 2011 then do;
		    * sum activity calendar;
			array actcal (*) PL210A PL210B PL210C PL210D PL210E PL210F 
		                     PL210G PL210H PL210I PL210J PL210K PL210L;
			array actcalf (*) PL210A_F PL210B_F PL210C_F PL210D_F PL210E_F PL210F_F 
		                      PL210G_F PL210H_F PL210I_F PL210J_F PL210K_F PL210L_F;
			array pl210 (*) PL210_1 PL210_2 PL210_3 PL210_4 PL210_5 
		          			PL210_6 PL210_7 PL210_8 PL210_9; 

			do i = 1 to dim(pl210);
				pl210(i) = 0;
			end;

			do i = 1 to dim(actcal);
				if actcalf(i) = 1 and actcal(i) ne 0 then pl210(actcal(i)) = pl210(actcal(i)) + 1;
			end;
		end;
		else do;
			* sum activity calendar;
			array actcal_11 (*) PL211A PL211B PL211C PL211D PL211E PL211F 
		                     PL211G PL211H PL211I PL211J PL211K PL211L;
			array actcalf_11 (*) PL211A_F PL211B_F PL211C_F PL211D_F PL211E_F PL211F_F 
		                      PL211G_F PL211H_F PL211I_F PL211J_F PL211K_F PL211L_F;
			array pl211 (*) PL211_1 PL211_2 PL211_3 PL211_4 PL211_5 
		          			PL211_6 PL211_7 PL211_8 PL211_9 PL211_10 PL211_11; 

			do i = 1 to dim(pl211);
				pl211(i) = 0;
			end;

			do i = 1 to dim(actcal_11);
				if actcalf_11(i) = 1 and actcal_11(i) ne 0 then pl211(actcal_11(i)) = pl211(actcal_11(i)) + 1;
			end;
		end;

	 end;

	drop i;

	RUN;

%end;

%if &f=p %then %do;

	* fill SELRES;
	 %if &ss=c %then %do;
		  PROC SQL;
		  create table dds.&ss&cc&yy.p as
			select a.*, b.RHID as PHID, b.AGE, b.RB245 as SELRES 
			from &ss&cc&yy.p0 as a left join dds.&ss&cc&yy.r as b  
		    on RB030 = PB030 and RB010 = PB010; 
		  RUN;
	 %end;

	 %if &ss=l or &ss=r %then %do;
		   PROC SQL;
		   create table dds.&ss&cc&yy.p as
			select a.*, b.RHID as PHID, b.AGE, b.RB245 as SELRES 
			from &ss&cc&yy.p0 as a left join dds.&ss&cc&yy.r as b  
		    on RB030 = PB030 and RB010 = PB010 and RB110 < 5; 
		  RUN;
	 %end;

	 %if &ss=e %then %do;
		  PROC SQL;
		  create table dds.&ss&cc&yy.p as
			select a.*, b.RHID as PHID, b.AGE, b.RB245 as SELRES 
			from dds.&ss&cc&yy.p as a left join dds.&ss&cc&yy.r as b  
		    on RB030 = PB030 and RB010 = PB010; 
		  RUN;
	 %end;
	  * calculate total incomes by HH;
	 %if &ss=c or &ss=l or &ss=r %then %do;
		 PROC SQL;
		 create table dds.&ss&cc&yy.h as
		   select distinct a.*,
		     HGROINC + sum(PGROINC) AS gross,
		     HNETINC + sum(PNETINC) AS net20,
		     CALCULATED net20 - HNINCS - sum(PNINCS)  AS net22,
		     CALCULATED net22 - sum(PNINCP) AS net23
		   from &ss&cc&yy.h0 as a left join dds.&ss&cc&yy.p as b 
		   on PHID = HB030 and PB010 = HB010
		   group by HB030,HB010; 
		QUIT;
	%end;
%end;

%MEND SUPVAR;

%SUPVAR;

*** sort files by HID (PID) and YEAR ***;

%MACRO SORT;
%if &f=d %then %do;
	PROC SORT data=dds.&ss&cc&yy.d;
	by DB030 DB010;
	run;
%end;

%if &f=r %then %do;
	PROC SORT data=dds.&ss&cc&yy.r;
	by RHID RB030 RB010;
	run;
%end;

%if &f=h %then %do;
	PROC SORT data=dds.&ss&cc&yy.h;
	by HB030 HB010;
	run;
%end;
 
%if &f=p %then %do;
	PROC SORT data=dds.&ss&cc&yy.p;
	by PHID PB030 PB010;
	run;
%end; 

%MEND SORT;

%SORT;
