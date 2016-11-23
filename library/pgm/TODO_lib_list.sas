/** \cond */
%macro lib_list(name_list=_list_lib_) ;

proc sql ;
select distinct libname into: &name_list from dictionary.tables ;
quit ;

%mend ;