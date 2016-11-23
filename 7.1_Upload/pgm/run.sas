
%create_list(prompt_name=action,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=geo,ptype=string,penclose=yes,pmultipl=yes,psepar=) ;	
%create_list(prompt_name=mode,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=RDB_indicators,ptype=string,penclose=no,pmultipl=yes,psepar=&LIST_SEPARATOR) ;	
%create_list(prompt_name=RDB2_indicators,ptype=string,penclose=no,pmultipl=yes,psepar=&LIST_SEPARATOR) ;	
%create_list(prompt_name=years,ptype=integer,penclose=no,pmultipl=yes,psepar=) ;	

option cmplib=WORK.funcs;


%MACRO sFData;
%local yyyy;
%let dsn=&TMPDSN;
%let tabs0=&RDB_indicators.&LIST_SEPARATOR.stop;
%put &tabs0;
%let i=1;
%put c_rdb=&c_rdb;

%do %until (%scan(&tabs0,&i,&LIST_SEPARATOR)=stop);

	/* PROC DATASETS lib=work kill nolist;
	quit;
	*/

	%put tabs0=&tabs0;
	%let ind=%scan(&tabs0,&i,&LIST_SEPARATOR);
	%put ind=&ind;
	%let yyyy=; 
		
	/* possibly rename the indicator
	 * this is typically the case of PNS2=>PNP2, PNS11=>PNP10, PNP11=>PNP3 */
	%let ind=%rule_tab_rename(&ind);

	/* set that data are available; possibly update the uploaded year (e.g., ad-hoc module) */
	%put =================check data;
	%data_check(&ind, %quote(&geo), %quote(&years), lib=c_rdb, _yyyy_=yyyy);

	%put yyyy=&yyyy; 

	%if %length(%quote(&yyyy))>0 %then %do;
		%put =================define file;
		%ncfile_define(&ind, %quote(&yyyy), _ncfile_=ebfile); /*output is returned*/

		/* extract the data into a temporary table */
		%put =================extract data;
		%data_extract(&dsn, /*output*/
					  &ind, %quote(&yyyy), lib=c_rdb /*input*/);

		/* actually create the file, i.e. write into it */
		%put =================create file;
		%ncfile_write(%quote(&ebfile), /*output*/
					  &dsn, &ind, %quote(&geo), %quote(&yyyy)/*input*/);

		/* upload the file */
		%put =================upload file;
		%ncfile_upload(%quote(&ebfile), &action);
		 
	%end;
	/* else: do nothing, the dataset is empty */
	
	
	%let i=%eval(&i+1);
%end;

%MEND sFData;

%sFData;




%macro _example_write_ebfile;
%let tab=DI05;		
libname rdb "&c_rdb";

%local yyyy; /* %let yyyy=; */
%local ncfile; /* %let ncfile=; */

%check_ebdata(&tab, %quote(&geo), %quote(&years), lib=rdb, _yyyy_=yyyy);

%if %length(%quote(&yyyy))>0 %then %do;
	%let ebfile=%define_ebfile(&tab, %quote(&yyyy));
	%create_ebfile(&tab, %quote(&ebfile), %quote(&geo), %quote(&yyyy), lib=rdb);
	/* %upload_ebfile(%quote(&ncfile), &action, &target); */
%end;

%mend _example_write_ebfile;
/* %_example_write_ebfile; */
