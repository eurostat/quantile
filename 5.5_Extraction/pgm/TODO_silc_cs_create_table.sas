%macro silc_cs_create_table(silc_lib,list_var,odsn,level,year,year_end=,list_country=,olib=work) ;

	%let level_possible = p h ;

	%if %macro_isblank(olib) %then %let olib=work;

	%if %error_handle(ErrorInputParameter, 
		%list_find(%upcase(&level_possible),%upcase(&level)) EQ ,		
		txt=%bquote(!!! Level &level does not exist - You may use the following keywords: %list_quote(%upcase(&level_possible),mark=_empty_) !!!)) %then
	%goto exit;

	/* 
	%if %macro_isblank(list_country) %then %do ;
		%var_to_list(c%substr(&year,3,2)d,db020,distinct=yes,lib=&silc_lib,_varlst_=list_country) ;
	%end ;*/

	%let list_tab = d h p r ;

	%do j = 1 %to 4 ;

		%let tab = %scan(&list_tab,&j) ;
		%let var_in_&tab = ;
		%let merge_&tab = ;
		%let var_to_keep_&tab = ;
		%ds_contents(c%substr(&year,3,2)&tab,_varlst_=var_in_&tab,varnum=no,lib=&silc_lib) ;

		%if %scan(%list_find(&list_var,_all_&tab._,casense=no),1) > 0 %then %do ;
			%let list_var = %list_replace(&list_var,_all_&tab._,&&var_in_&tab,casense=no) ;
		%end ;

		%if %list_length(%list_intersection(&&var_in_&tab,&list_var,casense=no)) > 0 %then %do ;
			%silc_cs_append_table(&silc_lib,&tab,&year,year_end=&year_end,list_country=&list_country) ;
			%let merge_&tab = 1 ;
		%end ;
	%end;


	%do j = 1 %to 4 ;

		%let tab = %scan(&list_tab,&j) ;

		%if &&merge_&tab = %then %goto skip ;

		%if %error_handle(ErrorInputParameter, 
			%ds_check(&tab) EQ 1,		
			txt=%bquote(!!! Missing tables! Cannot perform further !!!)) %then
		%goto exit;

		%let var_available = ;
		%ds_contents(&tab,_varlst_=var_available) ;

		%let var_to_keep_&tab = %list_intersection(&list_var,&var_available,casense=no) ;
		/* patch pdb */
		%let var_to_keep_&tab = %list_remove(&&var_to_keep_&tab,lasttime lastup ppp rate) ;

		%skip:

	%end ;

	%if &level = p %then %do ;

		proc sql ;
		create table &olib..&odsn as
		select p.pb010, p.pb020, p.pb030, floor(p.pb030/100) as hb030
		%if %list_length(&var_to_keep_p) > 0 %then %do ;
			, p.%list_quote(&var_to_keep_p,mark=_empty_,rep=%str(, p.))
		%end ;
		%if %list_length(&var_to_keep_r) > 0 %then %do ;
			, r.%list_quote(&var_to_keep_r,mark=_empty_,rep=%str(, r.))
		%end ;
		from p, r where p.pb010 = r.rb010 and p.pb020 = r.rb020 and p.pb030 = r.rb030 ;
		create table &olib..&odsn as
		select p.pb010, p.pb020, p.pb030, h.hb030
		%if %list_length(&var_to_keep_h) > 0 %then %do ;
			, h.%list_quote(&var_to_keep_h,mark=_empty_,rep=%str(, h.))
		%end ;
		from &olib..&odsn as p, h where p.pb010 = h.hb010 and p.pb020 = h.hb020 and p.hb030 = h.hb030 ;
		%if %list_length(&var_to_keep_d) > 0 %then %do ;
			create table &olib..&odsn as
			select p.pb010, p.pb020, p.pb030, p.hb030, %list_quote(&var_to_keep_d,mark=_empty_,rep=%str(, d.))
			from &olib..&odsn as p, d where p.pb010 = d.db010 and p.pb020 = d.db020 and p.hb030 = d.db030 ;
		%end ;
		quit ;
	%end ;

	%if &level = h %then %do ;

		%if %list_length(&var_to_keep_p) > 0 or %list_length(&var_to_keep_r) > 0 %then %do ;
			%put Cannot retrieve individual information at the household level if no reference person is defined ;
			%goto exit ;
		%end ;

		proc sql ;
		create table &olib..&odsn as
		select h.hb010, h.hb020, h.hb030
		%if %list_length(&var_to_keep_h) > 0 %then %do ;
			, h.%list_quote(&var_to_keep_h,mark=_empty_,rep=%str(, h.))
		%end ;
		%if %list_length(&var_to_keep_d) > 0 %then %do ;
			, d.%list_quote(&var_to_keep_d,mark=_empty_,rep=%str(, d.))
		%end ;
		from h, d where h.hb010 = d.db010 and h.hb020 = d.db020 and h.hb030 = d.db030 ;
		quit ;
	%end ;

	%if %upcase(&olib) = WORK %then %let list_to_delete = %list_difference(&list_tab,&odsn) ;
	%else %let list_to_delete = &list_tab ;

	%work_clean(&list_to_delete) ;

	%exit:

%mend ;



%macro _example_silc_cs_create_table ;

	libname silc "&g_pdb" ;

	%put (i): Create a table with an unknown zone ;

	%silc_cs_create_table(silc,hy020 db090,test,h,2006,year_end=2008,list_country=EU) ;

	proc sort data=test ;
	by hb010 hb020 ;
	run ;

	data test ;
	set test ;
	by hb010 hb020 ;
	if first.hb020 ;
	run ;

	%ds_print(test) ;
	%work_clean ;


	%put (ii): Create a table with countries from the EU27 ;

	%silc_cs_create_table(silc,hy020 db090,test,h,2006,year_end=2008,list_country=EU27) ;

	proc sort data=test ;
	by hb010 hb020 ;
	run ;

	data test ;
	set test ;
	by hb010 hb020 ;
	if first.hb020 ;
	run ;

	%ds_print(test) ;
	%work_clean ;


	%put (iii): Create a table for FR with all variables from D and H tables ;

	%silc_cs_create_table(silc,_all_h_ _all_d_,test,h,2010,list_country=FR) ;

	proc sort data=test ;
	by hb010 hb020 ;
	run ;

	data test ;
	set test ;
	by hb010 hb020 ;
	if first.hb020 ;
	run ;

	%ds_print(test) ;
	%work_clean ;

%mend ;

option nomprint nonotes nosource ;
*options source notes mprint ;
%_example_silc_cs_create_table ;
options notes source ;


				


		