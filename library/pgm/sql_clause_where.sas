%macro sql_clause_where(dsn
						, var
						, _varwhere_=
						, op=
						, lab=
						, log=
						);

	%list_append(&varop, %list_quote(&varlab,rep=_EMPTY_), 
								zip=%quote(=), 
								rep=%quote( and )
						);
%mend sql_clause_where;
