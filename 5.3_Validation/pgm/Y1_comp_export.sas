
proc export data=work.discrete_diff
   outfile="&G_PING_RAWDB/&cc/&ss&yy./&ss&cc&yy._with_year_&y1._comparison_discrete_&sysdate..csv"
   dbms=csv
   replace;
run;

proc export data=work.cont_diff
   outfile="&G_PING_RAWDB/&cc/&ss&yy./&ss&cc&yy._with_year_&y1._comparison_continuous_&sysdate..csv"
   dbms=csv
   replace;
run;

