%let pgm_path = /ec/prod/server/sas/0eusilc/library/pgm ;
%let macro_lib = /ec/prod/server/sas/1eusilc/2.Personal_folders/Pierre/scripts/macros ;



%macro list_members(folder,suffix,partial,name_list=mylist) ;

%global &name_list ;

%let fileref = myfile ;

%let rc = %sysfunc(filename(fileref,"&folder")) ;
%let did = %sysfunc(dopen(&fileref)) ;
%let memcount = %sysfunc(dnum(&did)) ;


%let &name_list = ;

%if &memcount > 0 %then %do ;
	%do n = 1 %to &memcount ;
		%let name = %sysfunc(dread(&did,&n)) ;
		%if (&suffix ne ) %then %do ;
			%if (&partial = ) %then %do ;
				%if %substr(&name,%eval(%length(&name)-%length(&suffix)),%eval(%length(&suffix)+1)) = .&suffix %then %do ;
					%let &name_list = &&&name_list %substr(&name,1,%eval(%length(&name)-%length(&suffix)-1)) ;
				%end ;
			%end ;
			%if (&partial ne ) %then %do ;
				%if %substr(&name,%eval(%length(&name)-%length(&suffix)),%eval(%length(&suffix)+1)) = .&suffix and %index(&name,&partial) > 0 %then %do ;
					%let &name_list = &&&name_list %substr(&name,1,%eval(%length(&name)-%length(&suffix)-1)) ;
				%end ;
			%end ;
		%end ;
		%if (&partial ne ) and (&suffix = ) %then %do ;
			%if %index(&name,&partial) > 0 %then %do ;
				%let &name_list = &&&name_list &name ;
			%end ;
		%end ;
		%if (&partial = ) and (&suffix = ) %then %do ;
			%let &name_list = &&&name_list &name ;
		%end ;
	%end ;
%end ;

%let rc = %sysfunc(dclose(&did)) ;

%mend ;

%list_members(folder=&pgm_path,suffix=sas,name_list=list_script) ;


libname maclib "&macro_lib" ;

options mstored sasmstore=maclib ;

%macro compile_macros ;

%do k = 1 %to %sysfunc(countw(&list_script)) ;

%let file = %scan(&list_script,&k) ;

data temp ;
infile "&pgm_path/&file..sas" termstr=crlf encoding='utf-8' dsd missover dlmstr="p!p" expandtabs;
format text $500. ;
informat text $500. ;
input text $ ;
run ;

data temp ;
set temp ;
retain keep_obs 0 ;
if lowcase(scan(text,1)) = "macro" and lowcase(scan(text,2)) = "&file" then keep_obs = 1 ;
if lowcase(scan(lag(text),1)) = "mend" and lag(keep_obs) = 1 then keep_obs = 0 ;
run ;

data temp ;
set temp ;
retain header 0 ;
if keep_obs = 1 and lag(keep_obs) = 0 then header = 1 ;
if header = 1 and index(text,";")>0 then do ;
	text = tranwrd(text,";"," / store ;") ;
	header = 0 ;
end ;
run ;

data _null_ ;
file "&macro_lib./script.sas" lrecl=36000 ;
set temp ;
put text ;
where keep_obs = 1 ;
run ;

%include "&macro_lib./script.sas" / source2 ;

%end ;

%mend ;

%compile_macros ;






