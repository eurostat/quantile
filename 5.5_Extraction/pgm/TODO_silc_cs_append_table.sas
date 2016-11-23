%macro silc_cs_append_table(silc_lib,list_table,year_start,year_end=,list_country=,olib=work,list_odsn=) ;

	%let tab_possible = d h p r ;

	%if %error_handle(ErrorInputParameter, 
		%list_difference(%upcase(&list_table),%upcase(&tab_possible)) NE ,		
		txt=%bquote(!!! Table(s) &list_table do(es) not exist !!!)) %then
	%goto exit;

	%if %macro_isblank(olib) %then %let olib=work;
	%if %macro_isblank(list_odsn) %then %let list_odsn = &list_table ;
	%else %if %list_length(&list_odsn) ne %list_length(&list_table) %then %do ;
		%put WARNING: The list for naming the output tables has not the same length than the list of input tables. ;
		%put Using default naming instead. ;
		%let list_odsn = &list_table ;
	%end ;

	/* in case you want only one year, you just need to leave the parameter year_end blank */
	%if %macro_isblank(year_end) %then %let year_end = &year_start ;

	/* in case list_country is blank, take all countries that appear at least once in the datasets */
	%if %macro_isblank(list_country) %then %do ;
		%var_to_list(d,db020,distinct=yes,_varlst_=list_country) ;
	%end ;

	/* check whether list_country is an aggregation, a list of countries or cannot be recognized */
	%let check_ctry = ;
	%str_isgeo(&list_country,_ans_=check_ctry) ;


	%do k = 1 %to %list_length(&list_country) ;
		%if %scan(&check_ctry,&k) = 0 %then %do ;
			%put WARNING: The code %scan(&list_country,&k) cannot be recognized. It will be discarded from the list. ;
			%let list_country = %list_remove(&list_country,%scan(&list_country,&k)) ;
		%end ;
		%if %scan(&check_ctry,&k) = 2 %then %do ;
			%let add= ;
			%ctry_define(%scan(&list_country,&k),year=2015,_ctrylst_=add) ; 								/* ----> remove 2015 once the macro has been updated */
			%let list_country = %list_remove(&list_country,%scan(&list_country,&k)) &add ;
		%end ;
	%end ;

	/* in case list_country is blank, this means that all codes in the list could not be recognized. Stop here. */
	%if %macro_isblank(list_country) %then %do ;
		%put ERROR: Parameter list_country does not contain any recognizable code. Please check. ;
		%goto exit;
	%end ;



	/* check that the library contains the expected tables */

	%do k = 1 %to %list_length(&list_table) ;

		%let tab = %scan(&list_table,&k) ;
		%do yy = &year_start %to &year_end ;
			%let y = %substr(&yy,3,2) ;
			%if %error_handle(ErrorInputParameter, 
				%ds_check(c&y.&tab,lib=&silc_lib) EQ 1 ,		
				txt=%bquote(!!! Cannot find c&y.&tab in library &silc_lib !!!)) %then
			%goto exit;
		%end ;
	%end ;




	%do k = 1 %to %list_length(&list_table) ;

		%let tab = %scan(&list_table,&k) ;
		%let tab_out = %scan(&list_odsn,&k) ;
		data &olib..&tab_out ;
		set 
		%do yy = &year_start %to &year_end ;
			%let y = %substr(&yy,3,2) ;
			&silc_lib..c&y.&tab. 
		%end ;
		;
		where &tab.b020 in (%list_quote(&list_country)) ;
		run ;

	%end ;

	%exit:


%mend ;


%macro _example_silc_cs_append_table ;

	%put (i): Test selection 2006-2008 on AT ;

	libname silc "&g_pdb" ;

	%silc_cs_append_table(silc,h,2006,year_end=2008,list_country=AT,list_odsn=h_at) ;

	data test ;
	set h_at ;
	if _n_ <= 5 ;
	run ;

	%ds_print(test) ;
	%work_clean(h_at test) ;

	%put (ii): Test selection 2008 on euro area ;

	%silc_cs_append_table(silc,h,2008,list_country=EA,list_odsn=h_ea) ;

	data test ;
	set h_ea ;
	if _n_ <= 5 ;
	run ;

	%ds_print(test) ;
	%work_clean(h_ea test) ;

%mend ;

options mprint ;

%_example_silc_cs_append_table ;

