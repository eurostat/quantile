put 'title1 "Check #128 / %nrstr(&datum)";';
put 'title2 "%nrstr(&ccnam) - %nrstr(&surtyp) survey %nrstr(&suryear)";';
put 'title3 "Structural - Error: RB250 - Personal data record is missing in P-file or RB250 not filled correctly ";';
put "PROC SQL;";
put "Create table tempo as";
put "select RB010,RB030,RB070,RB080,RB250,PB010,PB030 from &ss.%nrstr(&cc).&yy.r as a 
 full join &ss.%nrstr(&cc).&yy.p as b on RB030 = PB030 and RB010 = PB010 and a.RHID = b.PHID
 where (RB250 in (11,12,13,14) and PB030 = .) or ((RB250 not in (11,12,13,14)) and PB030 ne .);";
put "Select * from tempo(obs=%nrstr(&errmax)) as a
 order by RB010,RB030;";
put "Insert into errtabl set cod = 128 , error = (select count(*) from tempo);";
put "QUIT;";