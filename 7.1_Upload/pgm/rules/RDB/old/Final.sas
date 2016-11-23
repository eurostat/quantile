
/***********************************************************************************************************************/
/*  program to create  CSV file with the Indicators list calculated in the last  &n_days days but NOT sent in Eurobase */
/*  0.Select the indicators calculated in teh last &n_days RDBLOGX                          */
/*  1.split the rows with more  years  for the indicators sending in Eurobase  (uploading)                 */
/*  2.split the rows with more countries sending in Eurobase  (uploading daatsets)                           */

/* this macro variable is assigned here if you want run the program in standalone */
*%let n_days=0; /* macro variable  to define the range of the time*/

%macro Indicators;
/**********************************************************************/
/* STEP 0. selection of all lines written for indicators calculation
           formatted in order to have one line for each indicators  */

 data IndicCalc;
	set log.log;
	where index(report,'calculated')>0;
	a=index(report,'-');
	b=index(report,'(');
	c=index(report,'+');
run;
data indicCalc; set indicCalc;
s=a-4;
p=3;
if (substr(report,3,5)='DB020' or 
	substr(report,3,5)='NUTS2' or substr(report,3,5)='NUTS1') then
	do
	a=a+5;
		s=2;
		p=11;
	end;
run;
/* delete indicator calculation done  BEFORE 10JAN2011  changed 28/5/2013*/
data IndicCalc(rename=(user=user_up)); set IndicCalc;if date <  '10JAN2011'd  then delete;run;
PROC SQL;
	Create table RDBLOG as
		select date as data, user_up as userid, substr(report,p,s) as country, substr(report,a+2,4) as year,a,b,substr(report,a+9,b-1-a-8) as indic
			from IndicCalc
	;
quit;

/* delete longitudinal datasets and cleaning */
data  rdblog ( drop=a b ) ;
	set rdblog;
	
		indic=compress(upcase(indic));
		if indic = 'DDD21' then indic='MDDD21';
run;
data  rdblog;set  rdblog;
if indic in ('LI21','LVHL30','LVHL32','LVHL33','LVHL34',' LVHL35') then delete;
if country  in ('EA12','EA13','EA15','EU15','EA','EA16') then delete;
run;
proc sort data=rdblog nodupkey;
	by data country year indic;
run;

data rdblogx (rename=(yearx=year));set rdblog;
	yearx=input(year,8.);
	drop year;
	format a DDMMYY10.;
	a=date(); 
	actual=datdif(data, a, 'act/act');
run;
 
data rdblogx(drop=a actual);set rdblogx;
	where  actual <= &n_days ;
run;
%mend Indicators;
%Indicators;

/*STEP 1. IMPORT all indicators   sent in Eurobase   */
proc import      datafile="&idbrdb/log/log.csv"     dbms=csv     out=uplist replace;  
getnames=no; 
guessingrows=32767; /* this is the maximum for Base SAS 9.2 */ 
run; 
proc sort data=uplist; by var1;run;

data uplist;set uplist;var4=compress(var4);run;
data uplist(drop=var6 rename=(var5=country));set uplist;
format a DDMMYY10.;
a=date();run;

/* Select indicators sent to Eurobase in the last &days    */
data difuplist;
set uplist ;
     actual=datdif(var1, a, 'act/act');
     
   run;
   data difuplist(drop=a actual);
   set difuplist;
   where  actual <= &n_days ;
   run;

  /* STEP1.1 split dataset to : one (UpLoadInd) with one year and other (TEST1) more years and split the last */
  /*         in one row for  each year */

  data UpLoadInd(drop=var4 rename=(var5=country)) test1(drop=year);
	set difuplist;
 
	if  substr(var4,5,1)='-' then output test1;
	else  do;
	    year=input(var4,8.);
        output UpLoadInd;
    
	end;
  run; 
 
%macro SpliYear;

data test2(keep=var1 var2 var3 country year word) ; set test1 ;
	
		delim = '-';
   		nwords = countw(var4, delim);

   		do count = 1 to nwords;
     		 word = scan(var4, count, delim);
      		 output test2;
  		 end;
run;
data test2(drop=word);set test2;
	year = input(word,8.); 
run;
data uploadind(rename=(var1=data var3=indic var2=userid)); set uploadind test2;run;

PROC DATASETS lib=work  nolist;
	delete test test1 test2 ;
QUIT;

%mend SpliYear;
%SpliYear;
/* STEP 2.3 country : create one file with one country (uploadind)and onother with more (test3) in the same row*/
 
data uploadind;set uploadind;
a= substr(country,3,1);
b= substr(country,4,1);
c= substr(country,5,1);
d= substr(country,6,1);
e= substr(country,7,1);
run;

data uploadind(drop=end);set uploadind;
y=0;
if a =' ' and b=' ' and c=' ' and d=' ' and end=' ' then y=1;
if a <>' ' and b<>' ' and c=' ' and d=' ' and e=' ' then y=1;
if a <>' ' and b<>' ' and c<>' ' and d=' ' and e=' ' then y=1;
run;
data uploadind(drop=y a b c d e) test3(drop=y a b c d e);
set uploadind;
if  y =0  then output test3;  /* datasets with more countries */
if y=1 then output uploadind; /* datasets with one country */
run;
/* STEP 2.4 country: rows with more countries are splitted in lines with only one country */

data test4(drop=country modif delim nwords count rename=(word=country));
set test3;
   delim = ' ';
   modif = 'mo';
   nwords = countw(country, delim);
   do count = 1 to nwords;
      word = scan(country, count, delim);
      output;
   end;
run;

data test5; format data userid indic country year;set test4;run;

/*  Merge two datasets  in order to have only ome datasets with all countries line by line*/
data uploadind;set uploadind test5;run;

/*  remove the duplicate lines: line with same indicator same year same country but different data */
proc sort data=uploadind ;
	by  country indic year descending  data    ;
run;
proc sort data=uploadind  nodupkeys;
	by   country indic year;
run;

data rdblogx;set rdblogx;indic=lowcase(indic);run;
data uploadind;set uploadind;indic=lowcase(indic);run;
/* select unique records by country indic year; the last one by date */
proc sort data=rdblogx ;
	by  country indic year descending  data    ;
run;
proc sort data=rdblogx nodupkeys;
	by   country indic year;
run;
/* formatting RDBLOGX and UOLODIND */

data rdblogx;set rdblogx;
informat a $20.;
format a $20.;
length a $20;
a=country;
informat b $20.;
format b $20.;
length b $20;
b=indic;
run;
data uploadind ;set uploadind ;
informat a $20.;
format a $20.;
length a $20;
a=country;
informat b $20.;
format b $20.;
length b $20;
b=indic;
run;
data uploadind(rename=(a=country b=indic));set uploadind;
drop country indic;
run;
data rdblogx(rename=(a=country b=indic));set rdblogx;
drop country indic;
run;

%macro rep_final;
%let NO_data=0; /* to test if the datasets are empty */
%let rdbupl_obs=0;
/* to create name file with date and time  */
		%let Time      = %sysfunc(time(),time8.0);
		%let Time_HH   = %scan(&Time.,1,:);
		%let Time_MM   = %scan(&Time.,2,:);
		%let Time_SS   = %scan(&Time.,3,:);
		%let Time_run=&Time_HH..&Time_MM..&Time_SS;
		%let dat_time=&sysdate._&Time_run;
		%let f1=&ss&cc&yy._With_previousTrasmission_&dat_time..csv;
		*let fname1='&eusilc/&idbrdb/newcronos/Indic_NotSend_&dat_time..csv';
		%let fname1='&loaddb/Indic_NotSend_&dat_time..csv';
proc sql noprint;
			select count(*) into :rdb_obs from rdblogx;
quit;
proc sql noprint;
			select count(*) into :upl_obs from uploadind;
quit;

 data back_output; /* datasets to use in proc report when the result dataset from the comparison  is empty */
	Number_Of_indicator_Calculated=&rdb_obs;
	Number_Of_indicator_Uploaded=&upl_obs;
	gap_of_days=&n_days;
	data=date();
run;
/* STEP to COMPARE RDBLOGX (list of indicators calculated) UPLOADIND (list of indicators sent in eurobase) */
 	
%if &rdb_obs> 0 and  &upl_obs>0 %then %do; /* test if the two datasets to compare are empty */
	proc sql;
	create table file_output as select  a.* from rdblogx as a 
	left join uploadind as b on 
	a.country=b.country and a.year =b.year and  a.indic =b.indic
	where b.country is null and b.year is null and b.indic is null;
	run;
	 
    proc sql noprint;
			select count(*) into :rdbupl_obs from file_output;
   quit;
   %if &rdbupl_obs>0 %then %do;  /* no empty result file */
     proc sql;
	 	create table file_output1 as
 		select distinct  a.year ,a.indic,a.userid
	 	from file_output as a
 	 ;
	 quit;
	%end;

%end;
%else %do;
    %let NO_data=1;  /* one of them is  empty */
    data file_output; /* copied the dataset to use for proc report */
         set back_output;
    run;
 
%end;
%if &NO_data=1 or &rdbupl_obs>0 %then %do;
    data file_output;set file_output;format data DDMMYY10.;run;
	
	proc export data=file_output  outfile="&fname1 "
		dbms=dlm replace;
		delimiter=',';
	quit;	
 %end;

%if &rdb_obs> 0 and  &upl_obs>0 %then %do;
 	%if &rdbupl_obs>0 %then %do;
 	TITLE1 "Indicators calculated in the last  &n_days days but NOT sent in Eurobase";
	TITLE2 "look at the csv  file in newcronos folder";
		proc report data=file_output1 nowindows missing headline headskip
		style(header) =[background=CRIMSON foreground=white TEXTALIGN= c]  
        style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
                  cellwidth = 3cm};
		column    userid YEAR INDIC;
		define userid/ group;
		define YEAR / group;
		define INDIC / group ;
		run;
	%end;
	%else %do;
		%if &NO_data=0  %then %do;
    	TITLE1 "All Indicators calculated in the last  &n_days days have been sent in Eurobase";
   		TITLE2 " No CSV file is generated";
	    proc report data=back_output nowindows missing headline headskip
		style(header) =[background=CRIMSON foreground=white TEXTALIGN= c]  
        style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
                  cellwidth = 3cm};
		column    Number_Of_indicator_Calculated Number_Of_indicator_Uploaded gap_of_days;
		
		define Number_Of_indicator_Calculated /display; 
		define Number_Of_indicator_Uploaded /display;  
		define gap_of_days /display ;
		
		run;
		%end;
	%end;
%end;
%else %do;
TITLE1 " indicators calculated and  indicators uploaded in the last &n_days days ";
TITLE2 "look at the csv file in newcronos folder";
		proc report data=file_output nowindows missing headline headskip
		style(header) =[background=CRIMSON foreground=white TEXTALIGN= c]  
        style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
                  cellwidth = 3cm};
		column    Number_Of_indicator_Calculated Number_Of_indicator_Uploaded gap_of_days;
		
		define Number_Of_indicator_Calculated /display; 
		define Number_Of_indicator_Uploaded /display;  
		define gap_of_days /display ;
		
		run;
%end;
PROC DATASETS lib=work  nolist;
	delete test5 test3 test4 ;
QUIT;
%mend;
%rep_final;