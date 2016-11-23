
%macro lowcase(dsn); /* macro to rename the variables*/
%let dsid=%sysfunc(open(&dsn)); 
%let num=%sysfunc(attrn(&dsid,nvars)); 
 
data &dsn; 
set &dsn(rename=( 
%do i = 1 %to &num; 
%let var&i=%sysfunc(varname(&dsid,&i));   /*function of varname returns the name of a SAS data set variable*/
&&var&i=%sysfunc(lowcase(var&i)) /*rename all variables*/ 
%end;)); 
%let close=%sysfunc(close(&dsid)); 
run; 
%mend lowcase; 
%macro T_char; /*macro to identify charcter variables in error */
data listx;
set list;
%do i=1 %to &num;
	if upcase(substr(var&i,1,1))="X"   then vary=1  ;
%end;
run;

data listx;set listx;
if vary = . then delete;
run;
proc sql noprint;
			select count(*) into :c_obs from listx;
quit;
%mend;


%macro compare(NewFile,PreviousFile);
%let VChar=0;
%let nobs=0;

PROC DATASETS lib=work  nolist;
	delete vardif ;
QUIT;
PROC SORT DATA=back.&NewFile  OUT=WORK.Base_&NewFile;
   BY &ffile.B010
	 &ffile.B020
	 &ffile.B030;
RUN;

PROC SORT DATA=dds.&PreviousFile OUT=Compare_&PreviousFile;
   BY &ffile.B010
	 &ffile.B020
	 &ffile.B030;
RUN;
	

PROC COMPARE BASE=WORK.Base_&NewFile COMPARE=WORK.Compare_&PreviousFile
	CRITERION=0.00001
	METHOD=RELATIVE
	OUT=list (LABEL="Compare Data for Current and Previous &ffile")
	OUTSTATS=WORK.SUMMARY(LABEL="Compare Data Summary Statistics for Current and Previous &ffile trasmision")
	OUTDIF
	OUTNOEQUAL
	MAXPRINT=5; /*specifies the maximum number of differences to print PER-VARIABLE */
	ID &ffile.B010
	&ffile.B020
	&ffile.B030;
RUN;

PROC SQL;
   CREATE TABLE WORK.VarDif AS 
   SELECT t1._VAR_ as Numeric_Var_Name FORMAT=$30. LENGTH=30,
          t1._BASE_  as Number_of_Diff
      FROM WORK.SUMMARY as  t1
      WHERE t1._TYPE_ = 'NDIF' AND t1._BASE_ NOT = 0;
QUIT;

%if  %sysfunc(exist(VarDif)) %then
%do;
proc sql noprint;
			select count(*) into :obs from VarDif;
		quit;
%end;

%lowcase(list);
%T_char;
%if &c_obs > 0  %then %do; 
%let Vchar=1;
data nfile1;
	 format  Character_Var_Name $char80. ;
	 Character_Var_Name="Please, see the SAS_Report for character variables"; 
 run;
%end;
%else %do;
  data nfile1;
	 format  Character_Var_Name $char80. ;
	 Character_Var_Name="NO difference in character variables detected"; 
 run;
%end;

/* Test if VARLIST exist and selects the first 150 observations per file */

%if &nobs >151 %then %do;
       data VarDif;set VarDif(obs= 150);
       run;
 %end;
 %let ff=%upcase(&ffile);
 data nfile;
	 format Name_File $char10.  ;
	 Name_File="&ff file**********"; 
 run;

%if &obs >0  %then %do;
	%if not %sysfunc(exist(CompareResults)) %then %do;
		
  		    data CompareResults;
			   set nfile nfile1 VarDif;
		    run;
	%end;
	%else %do;
		
		data CompareResults;
			set CompareResults nfile nfile1 VarDif;
		run;
	%end;
%end;
%else %do;

	data Vardif;
		format Numeric_Var_Name $char30. ;
		Numeric_Var_Name="Numeric variables";
		Number_of_Diff=0;
 	run;
	%if not %sysfunc(exist(CompareResults)) %then %do;
	 
		    data CompareResults;
			   set nfile nfile1 VarDif;
		    run;
		
    %end;
	%else %do;

		data CompareResults;
			set CompareResults nfile nfile1 VarDif;
		run;
	%end;

%end;

%let Tval=%eval(&VChar+&Tval);
/*delete backup  datasets   */
PROC DATASETS lib=back nolist;
	delete &ss&cc&yy.&ffile;
QUIT;  
%mend;
%macro T1_Compare;
%global num c_obs;
%global Tval;
%global Vchar;
%let Tval=0;
ods html body="&G_PING_RAWDB/&cc/tmp/test.htm" style=Analysis;
/* to create name file with date and time  */
		%let Time      = %sysfunc(time(),time8.0);
		%let Time_HH   = %scan(&Time.,1,:);
		%let Time_MM   = %scan(&Time.,2,:);
		%let Time_SS   = %scan(&Time.,3,:);
		%let Time_run=&Time_HH..&Time_MM..&Time_SS;
		%let dat_time=&sysdate._&Time_run;
		%let f1=&ss&cc&yy._With_previousTrasmission_&dat_time..csv;
		%let fname1='&eusilc/&cc/&ss&yy/&ss&cc&yy._With_previousTrasmission_&dat_time..csv';
TITLE;
TITLE1 "Compare Data from Current  and Previous transmission";
FOOTNOTE;

%if &Number_T= 1 %then
	%do;
	
		%let listfile= d p h r ;
	 
		%let j=1;
		%let ffile=%scan(&listfile,&j,%str( ));
	
		%do  %while(&ffile ne );
			%if %SYSFUNC(EXIST(dds.&ss&cc&yy.&ffile)) and %SYSFUNC(EXIST(back.&ss&cc&yy.&ffile)) %then
				%do;
					%compare(&ss&cc&yy.&ffile,&ss&cc&yy.&ffile);
				%end;
			%else
				%do;
					/* output created when the input files  doesn't match */
					data work.ExistData;
						N_file="&ffile";
						country="&cc";
						year="&RYYYY";
						label="file doesn't exist in one or both transmissions";
					run;

					%if not %sysfunc(exist(NOComparefile)) %then
						%do;
							data NOComparefile;
								set ExistData;
							run;
						%end;
					%else
						%do;

							data NOComparefile;
								set NOComparefile ExistData;
							run;

						%end;
				%end;
            
			%let j=%eval(&j+1);
			%let ffile=%scan(&listfile,&j,%str( ));
		%end;

		%if %sysfunc(exist(CompareResults)) %then
			%do;
                
				proc sql noprint;
					select count(*) into :observations from CompareResults;
				quit;

            data compareResults;set compareResults;
				 label Numeric_Var_Name=' ';
				 label Number_of_Diff=' ';
			run;

			%if &observations =0 and &Tval=0 %then
					%do;
					data NoError;
							N_var = 0;
							format label $char80.;
							label =" NO errors have been detected";
						run;
        
   						proc print data=Noerror style(header) =[background=CRIMSON foreground=white TEXTALIGN= c just=center] noobs label
							style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
							cellwidth = 3cm WIDTH=250};
							Title1 c=CX172B6A  "NO differences  have been detected in  this comparison  for the files available for the comparison ";
													run;

						proc export data=NoError  outfile="&fname1 "
							dbms=dlm   replace;
							delimiter=',';
						quit;

					%end;
				%else
					%do;
						proc export data=CompareResults  outfile="&fname1 "
							dbms=dlm   replace;
							delimiter=',';
						quit;
						%sysexec chmod 777  $fname1;
					
						proc print data=CompareResults style(header) =[background=CRIMSON foreground=white TEXTALIGN= c ] noobs label
							style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
							cellwidth = 3cm WIDTH=180};
						title1 c=CX172B6A "List of numeric variables with changes: look at also &f1 file in country folder";
						title2 c=cxff0000 "Please, look at the HTML report for character variables";
						
					     run;
			
					  %end;
			%end;
	%end;
%else
	%do;
		/* HTLM generated when it is the first transmission  */
		data NoError;
			N_trasmission  = 1;
			format label $char80.;
			label ="No sas datasets from previous versions available for the comparison";
		run;
		


		proc print data=Noerror style(header) =[background=CRIMSON foreground=white TEXTALIGN= c just=center] noobs label
			style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
			cellwidth = 3cm WIDTH=180};
			Title1 c=CX172B6A  "First Transmission or no files available ";
		run;

		proc export data=NoError  outfile="&fname1 "
			dbms=dlm   replace;
			delimiter=',';
		quit;

	%end;

/*output generated when the input datasets doesn't match with the previous transmission some files is missing*/
%if &ss =l %then
	%let P_Type=Longitudinal;
%else %let P_Type=Cross Sectional;

%if %sysfunc(exist(NOComparefile)) %then
	%do;
	

		proc print data=NOComparefile style(header) =[background=CRIMSON foreground=white TEXTALIGN= c] noobs label
			style(column)={just=center foreground=#000000 background=white font_face=times font_size=3.1
			cellwidth = 3cm};
			title1 c=CX172B6A "Datafile  not available for %upcase(&cc) &yy &P_type comparison";
		run;

	%end;

/* clean working area   */

PROC DATASETS lib=work kill nolist;
QUIT; 

ods html close;
%mend;

%T1_Compare;
