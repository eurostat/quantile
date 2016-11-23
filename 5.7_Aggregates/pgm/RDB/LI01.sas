*** At-Risk-of-poverty threshold (illustrative values)
/* flags are taken from the existing data set  on 29/11/2010 */
***(a) One person household
***(b) Household with 2 adults and 2 dependent children***;
/* MG 20120109 modified the test for old_flag */
%macro UPD_li01(yyyy,Ucc,Uccs,flag) /store;

PROC DATASETS lib=work kill nolist;
QUIT;
%global CheckEmpty;
%let tab=LI01;
%let cc=%lowcase(&Ucc);
%let yy=%substr(&yyyy,3,2);
%let EU=0;
%if &Uccs=0 %then %let Uccs=("&Ucc");
%else %let EU=1; 


PROC SQL noprint;
Create table work.idb as 
	select distinct DB010, DB020, ARPT60, ARPT40, ARPT50, ARPT70,
					ARPT60M, ARPT40M, ARPT50M, rate, ppp
	from idb.IDB&yy
	where DB010 = &yyyy and DB020 in &Uccs;
Select distinct count(DB010) as N 
	into :nobs
	from  work.idb;
Create table work.li01 like rdb.li01; 
CREATE TABLE work.old_flag AS
SELECT 
      time,
      geo,
	  indic_il,
	  hhtyp,
	  currency,
	  iflag
	  FROM rdb.&tab
WHERE  time = &yyyy and geo="&Ucc"  
group by time, geo ,indic_il, hhtyp, currency ;

QUIT;
/* check if empty */
%macro ifanyobs(table);
%local dsid;
%let dsid = %sysfunc(OPEN(&table));

%if &dsid %then %do;
  %if %sysfunc(ATTRN(&dsid,ANY)) %then  %Let CheckEmpty="NO";
  %else %Let CheckEmpty="Yes";
  %let dsid = %sysfunc(CLOSE(&dsid));
%end;
%mend;



/* insert here */
%macro C_Flag;
  proc sort  data=work.old_flag;by hhtyp currency; run;
  data old_flag_a old_flag_b;
	set work.old_flag;
	if hhtyp in ("A1") then output  old_flag_a;
	if hhtyp in ("A2_2CH_LT14")then output old_flag_b;
  run;
%let listpi=EUR NAC PPS;
%let listan=LI_C_M40 LI_C_M50 LI_C_M60 LI_C_MD40 LI_C_MD50 LI_C_MD60 LI_C_MD70;
%let listdata=old_flag_a old_flag_b;
  %let j=1; 
  %let i=1; 
  %let k=1;
%let curr1=%scan(&listpi,&i,%str( ));    
%let libel1=%scan(&listan,&j,%str( ));  
%let namedata=%scan(&listdata,&k,%str( ));  

%do  %while(&namedata ne );  
%do  %while(&curr1 ne );  
     %let j=1; 
	 %let libel1=%scan(&listan,&j,%str( ));  
     %do  %while(&libel1 ne );    

     	 data a&k.&j.&i ;
    	 set   &namedata;
        
           if indic_il= "&libel1" and currency="&curr1" then do;
		      output a&k.&j.&i;
		   end;
		 run;
     	 %let j=%eval(&j+1); 
     	 %let libel1=%scan(&listan,&j,%str( ));  
	  %end;
	 %let i=%eval(&i+1); 
     %let curr1=%scan(&listpi,&i,%str( )); 
	 %put &curr1;
 %end;
 %let k=%eval(&k+1); 
 %let namedata=%scan(&listdata,&k,%str( )); 
 %let i=1;
 %let curr1=%scan(&listpi,&i,%str( ));   
 %let j=2;
  %let libel1=%scan(&listan,&j,%str( )); 
 %end;

%mend C_Flag;

%ifanyobs(old_flag);

%if &CheckEmpty="NO" %then %do;

data old_flag_a old_flag_b;
  set work.old_flag;
  if hhtyp in ("A1") then output  old_flag_a;
  if hhtyp in ("A2_2CH_LT14")then output old_flag_b;
run;
%C_Flag; 
%end;


/* end */

                
				%macro f_li01_0(arpt,libel);
				
				%if &libel = LI_C_MD60 %then %let KK=6;
				%if &libel = LI_C_MD40 %then %let KK=4;
				%if &libel = LI_C_MD50 %then %let KK=5;
				%if &libel = LI_C_MD70 %then %let KK=7;
				%if &libel = LI_C_M60 %then %let KK=3;
				%if &libel = LI_C_M40 %then %let KK=1;
				%if &libel = LI_C_M50 %then %let KK=2;
				%if &CheckEmpty="NO" %then %do;
				PROC SQL;
				Insert into work.li01 
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A1",
						currency="NAC",
						ivalue=(select idb.&arpt from work.idb),
						iflag=(select iflag from a1&kk.2), 
						/*iflag="&flag",*/
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A1",
						currency="EUR",
						ivalue=(select (idb.&arpt / idb.rate) from work.idb),
						iflag=(select iflag from a1&kk.1), 
						/*iflag="&flag",*/
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A1",
						currency="PPS",
						ivalue=(select (idb.&arpt / idb.ppp) from work.idb),
						iflag=(select iflag from a1&kk.3), 
						/*iflag="&flag",*/
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="NAC",
						ivalue=(select (idb.&arpt * 2.1) from work.idb),
						iflag=(select iflag from a2&kk.2), 
						/*iflag="&flag", */
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="EUR",
						ivalue=(select (idb.&arpt / idb.rate * 2.1) from work.idb),
						iflag=(select iflag from a2&kk.1), 
						/*iflag="&flag",*/
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="PPS",
						ivalue=(select (idb.&arpt / idb.ppp * 2.1) from work.idb),
						iflag=(select iflag from a2&kk.3), 
						/*iflag="&flag", */
						unrel=0,
						lastup="&sysdate",
						lastuser="&sysuserid";
				QUIT; 
				%end;
				%else %do;
				PROC SQL;
				Insert into work.li01 
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A1",
						currency="NAC",
						ivalue=(select idb.&arpt from work.idb),
						
						iflag="&flag",
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A1",
						currency="EUR",
						ivalue=(select (idb.&arpt / idb.rate) from work.idb),
						
						iflag="&flag",
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A1",
						currency="PPS",
						ivalue=(select (idb.&arpt / idb.ppp) from work.idb),
						
					    iflag="&flag",
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="NAC",
						ivalue=(select (idb.&arpt * 2.1) from work.idb),
						
					iflag="&flag", 
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="EUR",
						ivalue=(select (idb.&arpt / idb.rate * 2.1) from work.idb),
					
					iflag="&flag",
						unrel=0,
						lastup="&sysdate",
						lastuser= "&sysuserid"
					set geo=(select idb.DB020 from work.idb),
						time=(select idb.DB010 from work.idb),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="PPS",
						ivalue=(select (idb.&arpt / idb.ppp * 2.1) from work.idb),
						
					iflag="&flag", 
						unrel=0,
						lastup="&sysdate",
						lastuser="&sysuserid";
				QUIT; 
				
				
				%end;
				
				%mend f_li01_0;

				%macro f_li01_1(arpt,libel);
				PROC SQL noprint;
				Create table work.idbe as 
					select distinct DB010, DB020, EQ_INC20eur, RB050a  
					from idb.IDB&yy
					where DB010 = &yyyy and DB020 in &Uccs;
				QUIT;
				 
				PROC MEANS data=work.idbe median sumwgt qmethod=os noprint;  
				var EQ_INC20eur;
				id DB010;
				weight RB050a;
				output out=work.medi20 mean()=MEAN20 median()=MEDIAN20 sumwgt()=WGHT;
				run;

				PROC SQL;
				Create table work.ARPT20 as
				select DB010, WGHT, MEAN20, MEDIAN20,
					(MEDIAN20 * 0.6) as ARPT60, 
					(MEDIAN20 * 0.4) as ARPT40, 
					(MEDIAN20 * 0.5) as ARPT50, 
					(MEDIAN20 * 0.7) as ARPT70,
					(MEAN20 * 0.6) as ARPT60M, 
					(MEAN20 * 0.4) as ARPT40M, 
					(MEAN20 * 0.5) as ARPT50M 
				from work.medi20;
				QUIT;
                %let KK=0;
				%if &libel = LI_C_MD60 %then %let KK=6;
				%if &libel = LI_C_MD40 %then %let KK=4;
				%if &libel = LI_C_MD50 %then %let KK=5;
				%if &libel = LI_C_MD70 %then %let KK=7;
				%if &libel = LI_C_M60 %then %let KK=3;
				%if &libel = LI_C_M40 %then %let KK=1;
				%if &libel = LI_C_M50 %then %let KK=2;
				
				%if &CheckEmpty="NO" %then %do;
				PROC SQL;
				Insert into work.li01 
			
					set geo="&Ucc",
						time=(select DB010 from work.ARPT20),
						indic_il="&libel",
						hhtyp="A1",
						currency="EUR",
						ivalue=(select &arpt from work.ARPT20),
						iflag=(select iflag from a1&kk.1), 
						/*iflag="&flag", */
						unrel=0,
						lastup="&sysdate",
						lastuser="&sysuserid"
					set geo="&Ucc",
						time=(select DB010 from work.ARPT20),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="EUR",
						ivalue=(select (&arpt * 2.1) from work.ARPT20),
						iflag=(select iflag from a2&kk.1), 
						/*iflag="&flag", */
						unrel=0,
						lastup="&sysdate",
						lastuser="&sysuserid";
				QUIT; 
				%end;
				%else %do;
				PROC SQL;
				Insert into work.li01 
						set geo="&Ucc",
						time=(select DB010 from work.ARPT20),
						indic_il="&libel",
						hhtyp="A1",
						currency="EUR",
						ivalue=(select &arpt from work.ARPT20),
						iflag="&flag", 
						unrel=0,
						lastup="&sysdate",
						lastuser="&sysuserid"
					set geo="&Ucc",
						time=(select DB010 from work.ARPT20),
						indic_il="&libel",
						hhtyp="A2_2CH_LT14",
						currency="EUR",
						ivalue=(select (&arpt * 2.1) from work.ARPT20),
						iflag="&flag", 
						unrel=0,
						lastup="&sysdate",
						lastuser="&sysuserid";
				QUIT; 
				%end;
				%mend f_li01_1;
%if &nobs > 0 %then %do;

%f_li01_&EU(ARPT60,LI_C_MD60);
%f_li01_&EU(ARPT40,LI_C_MD40);
%f_li01_&EU(ARPT50,LI_C_MD50);
%f_li01_&EU(ARPT70,LI_C_MD70);
%f_li01_&EU(ARPT60M,LI_C_M60);
%f_li01_&EU(ARPT40M,LI_C_M40);
%f_li01_&EU(ARPT50M,LI_C_M50); 
 
* Update RDB;   
DATA  rdb.LI01;
set rdb.LI01(where=(not(time = &yyyy and geo = "&Ucc")))
    work.li01; 
if time ne . and geo ne "";
run; 
 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * LI01 (re)calculated *";		  
QUIT;

%end;
%else %do; 
PROC SQL;  
     Insert into log.log
     set date = "&sysdate"d, time = "&systime"t, user = "&sysuserid",
		 report = "* &Ucc - &yyyy * NO DATA !";		  
QUIT;
%end;


%mend UPD_li01;
