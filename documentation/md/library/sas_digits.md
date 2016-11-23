## digits {#sas_digits}
Return the number of digits necessary to represent a NUMERIC value.

	%let digs=%digits(value);

### Argument
`value` : input numeric value to represent.

### Returns
`digs` : the number of digits (in base 10) necessary to represent the number `value`.

### Examples
The simple runs:

	%let dig1=%digits(10);
	%let dig2=%digits(999.4);

return `dig1=2` and `dig2=3` respectively.

Run macro `%%_example_digits` for more examples.

### Notes
1. In short, the macro simply returns:

        %sysevalf(%sysfunc(floor(%sysfunc(log(&value))/%sysfunc(log(10)) + 1)));
2. This macro can be useful to encode and/or (re)format variables in a table, _e.g._ by
finding the maximum value or the number of occurrences of the variables in the table.
