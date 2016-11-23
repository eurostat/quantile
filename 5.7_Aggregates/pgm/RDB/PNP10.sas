*** Relative median income ratio Gender differences ***;



*** only single HH ***;



*** gender differences (M-F) ***;



*** changed age format 4 November 2010 ***;

%macro UPD_pnp10(yyyy,Ucc,Uccs,flag);

PROC DATASETS lib=work kill nolist;


QUIT;


%let tab=pnp10;

%let NOT_old_flag="Not";

%let cc=%lowcase(&Ucc);

%let yy=%substr(&yyyy,3,2);

%let EU=0;

%if &Uccs=0 %then %do; 

%let Uccs=("&Ucc");


PROC FORMAT;



   VALUE f_age (multilabel)



		0 - 64 = "Y_LT65"



		65 - HIGH = "Y_GE65"



		0 - 74 = "Y_LT75"



		75 - HIGH = "Y_GE75"



		0 - 59 = "Y_LT60"



		60 - HIGH = "Y_GE60";

	VALUE f_sex (multilabel)

		1 = "M"
		2 = "F"
		1 - 2 = "T";
RUN;


*** total ***; 

%let hhtyp=TOTAL;

PROC SQL noprint;

Create table work.idb as 



	select DB010, DB020, DB030, RB030, RB050a, Age, RB090, EQ_INC20 



	from idb.IDB&yy



	where age ge 0 and DB010 = &yyyy and DB020 in &Uccs;

Select distinct count(DB010) as N 

	into :nobs

	from  work.idb;

Create table work.&tab like rdb.&tab; 

CREATE TABLE work.old_flag AS


SELECT 

      time,

      geo,

	  hhtyp,

	  sex,

	  indic_il,

	  iflag


FROM rdb.&tab

WHERE  time = &yyyy and geo="&Ucc" ;

QUIT;


%if &nobs > 0

%then %do;

				%macro f_pnp10_0;
				PROC MEANS data=work.idb median sumwgt qmethod=os noprint;
				format AGE f_age15.; 
				format RB090 f_sex3.; 
				class AGE /MLF;
	  		class RB090 /MLF;

				var EQ_INC20;
				weight RB050a;
				output out=med median()=medi sumwgt()=c_sumwgt;
				run;
				%rel(Y_GE65,Y_LT65,R_GE65_LT65,T);
			    %rel(Y_GE65,Y_LT65,R_GE65_LT65,M);
				%rel(Y_GE65,Y_LT65,R_GE65_LT65,F);
				%rel(Y_GE75,Y_LT75,R_GE75_LT75,T);
				%rel(Y_GE75,Y_LT75,R_GE75_LT75,M);
				%rel(Y_GE75,Y_LT75,R_GE75_LT75,F);
				%rel(Y_GE60,Y_LT60,R_GE60_LT60,T);
				%rel(Y_GE60,Y_LT60,R_GE60_LT60,M);
				%rel(Y_GE60,Y_LT60,R_GE60_LT60,F);
				%mend f_pnp10_0;
				%macro rel(Y1,Y2,R,S);
				/* to check if old_flag  is empty  */
						proc sql;
							Select distinct count(iflag) as N 
							into :nobs
							from  old_flag;
						quit;
						%if &nobs = 0 %then %do;
							%let NOT_old_flag="Yes";
						%end;

           /* end check */
				%if &NOT_old_flag="Not" %then %do;
			    data _null_;
		        set old_flag;
                 if indic_il ="&R" and sex="&S" and hhtyp="&hhtyp"  then  call symput("newflag",compress(iflag));

				run;

			%end;
			%else %do;
			 %let newflag=" "; 
			%end;

				PROC SQL;

				INSERT into &tab SELECT 

					"&Ucc" as geo,

					&yyyy as time,
					"&hhtyp" as hhtyp,



					f1.RB090 as sex,



					"&R" as indic_il,



					(f1.medi / f2.medi) as ivalue,



				    "&newflag" as iflag,



					(case when f1._freq_ < 20 then 2



						  when f1._freq_ < 50 then 1



						  else 0



					      end) as unrel,



					f1._freq_ as ntot,
					f1.c_sumwgt as totwgh,
					"&sysdate" as lastup,
					"&sysuserid" as	lastuser 

				FROM med as f1 join med as f2 on f1.RB090 = f2.RB090 

				WHERE f1.AGE="&Y1" and f2.AGE="&Y2" and f1._type_ = 3 and f1.RB090="&S";

				QUIT;
				%mend rel;
%f_pnp10_0;
%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA(TOTAL) !";		  
QUIT;
%end;



*** single ***;



%let hhtyp=A1; 

PROC SQL noprint;

Create table work.idb as 
	select DB010, DB020, DB030, RB030, RB050a, Age, RB090, EQ_INC20, HT 
	from idb.IDB&yy
	where HT=5 and age ge 0 and DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 


	into :nobs

	from  work.idb;
QUIT;

%if &nobs > 0

%then %do;

%f_pnp10_0;

%end;

%else %do; 

PROC SQL;  

     Insert into log.log

     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",

		 report = "* &Ucc - &yyyy * NO DATA(A1) !";		  

QUIT;

%end;

*genderdiff;

PROC SQL;

Create table work.M as select * FROM work.&tab WHERE sex = "M";
Create table work.F as select * FROM work.&tab WHERE sex = "F";
quit;
%macro genderdiff(HTY,R);

%let NOT_old_flag="Not";


		/* to check if old_flag  is empty  */

					proc sql noprint;
							Select distinct count(iflag) as N 
							into :nobs
							from  old_flag;
						quit;
						%if &nobs = 0 %then %do;
							%let NOT_old_flag="Yes";
						%end;
           /* end check */
				%if &NOT_old_flag="Not" %then %do;
			   data _null_;
               set old_flag;
               if indic_il ="&R" and sex="DIFF" and hhtyp="&HTY" then  call symput("newflag",compress(iflag));
				run;
			%end;
			%else %do;

				%let newflag=" "; 
			%end;

proc sql;

INSERT into &tab SELECT 

	"&Ucc" as geo,

	&yyyy as time,

	"&HTY" as hhtyp,

	"DIFF" as sex,
	"&R"  as indic_il,
	(M.ivalue - F.ivalue) as ivalue,
    "&newflag" as iflag,
	(case when min(M.ntot,F.ntot) < 20 then 2
		  when min(M.ntot,F.ntot) < 50 then 1
		  else 0
	      end) as unrel,
	(F.ntot + M.ntot) as ntot,

	(F.totwgh + M.totwgh) as totwgh,
	"&sysdate" as lastup,

	"&sysuserid" as	lastuser 



FROM work.M join work.F on M.indic_il = F.indic_il and M.hhtyp = F.hhtyp and "&R" =M.indic_il and "&HTY" = M.hhtyp;


QUIT; 



%mend genderdiff;

%genderdiff(TOTAL,R_GE65_LT65);

%genderdiff(TOTAL,R_GE75_LT75);


%genderdiff(TOTAL,R_GE60_LT60);

%genderdiff(A1,R_GE65_LT65);

%genderdiff(A1,R_GE75_LT75);

%genderdiff(A1,R_GE60_LT60);

%end;

%else %do; 

%let EU=1; 
PROC SQL;
Create table work.rdb as 
	select hhtyp, indic_il, sex, ivalue, totwgh, ntot,
			(ivalue * totwgh) as wval
	from rdb.&tab
	where time = &yyyy and geo in &Uccs;
Select distinct count(indic_il) as N 
	into :nobs

	from  work.rdb;
	/*
Create table work.&tab like rdb.&tab; */

QUIT;

%if &nobs > 0



%then %do;



proc sql;



CREATE TABLE work.old_flag AS



				SELECT distinct



					geo,



					time,



					hhtyp,



					sex,



					indic_il,



					iflag



				FROM rdb.&tab



				WHERE  time = &yyyy and geo="&Ucc" ;quit;



				/* to check if old_flag  is empty  */



						proc sql;



							Select distinct count(iflag) as N 



							into :nobs



							from  old_flag;



						quit;



					



						%if &nobs = 0 %then %do;



							%let NOT_old_flag="Yes";



						%end;



						



           /* end check */



				



				proc sql;



				create table work.&tab as select  hhtyp,sex, indic_il,



					(sum(wval) / sum(totwgh)) as ivalue,



						(case when sum(ntot) < 20 then 2



						  when sum(ntot) < 50 then 1



						  else 0



					      end) as unrel,



						  sum(ntot) as ntot,



    					  sum(totwgh) as totwgh,



						 "&sysdate" as lastup,



					     "&sysuserid" as	lastuser 



					from work.rdb



				    group by rdb.indic_il, rdb.hhtyp, rdb.sex;



				quit;



					



					/* merge the output dataset plus old_flag and insert variables when the old_flg is empty ; */



	



		%if &NOT_old_flag="Yes" %then %do;



			data &tab;



			set &tab;



				geo="&Ucc" ;



				time=&yyyy;



				iflag=" ";



			run;



		%end;



		%else %do;



			data &tab; merge &tab  				



			old_flag ;	



			run;			



		%end;



						



				/* format the output dataset; */



				data &tab;



				format geo   time  hhtyp sex indic_il ivalue iflag unrel ntot totwgh  lastup lastuser; 



				set &tab; run;



				/*



PROC SQL;



INSERT INTO &tab SELECT 



	"&Ucc" as geo,



	&yyyy as time,



	rdb.hhtyp,



	rdb.sex,



	rdb.indic_il, 



	(sum(wval) / sum(totwgh)) as ivalue,



	 "" as iflag, 



	 	(case when sum(ntot) < 20 then 2



		  when sum(ntot) < 50 then 1



		  else 0



	      end) as unrel,



	sum(ntot) as ntot,



	sum(totwgh) as totwgh,



	"&sysdate" as lastup,



	"&sysuserid" as	lastuser 



FROM work.rdb 



group by rdb.indic_il, rdb.hhtyp, rdb.sex;



QUIT;*/



%end;



%else %do; 



PROC SQL;  



     Insert into log.log



     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",



		 report = "* &Ucc - &yyyy * NO DATA !";		  



QUIT;



%end;







%end;


* Update RDB;

DATA  rdb.&tab;


set rdb.&tab(where=(not(time = &yyyy and geo = "&Ucc")))

    work.&tab; 

run;


PROC SQL;  

     Insert into log.log

     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",



		 report = "* &Ucc - &yyyy * pnp10 (re)calculated *";		  
QUIT;
%mend UPD_pnp10;
