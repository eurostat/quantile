## Coding: tips and techniques {#mainpage_programming}

If a manual task can be automated, it should be automated. That applies to creating standard 
[SAS macros](@ref SAScoding) and/or [R functions](@ref Rcoding), and using common/conventional 
standards to save yourself work just (as much as it applies to creating test/example/check 
utilities to save your colleagues work). 


We provide hereby some basic guidelines for developing your own code to be integrated into `PING`. 
We desire a consistent look and feel for the SAS code being developed and integrated onto `PING`
platform, and need faster program development cycles. For that purppose, the adoption of common 
coding guidelines ensures the consistency of the programs developed herein. 

In their current state, the guidelines are based on common sense, often derived from existing 
litterature, or practical uses that may seem arbitrary. Improvements are still welcome/possible. 

<a name="SASprogramming"></a>
### SAS programming {#SASprogramming}
### SAS programming

Some generic principles need to be taken into account into our developments:
1. program according to functional specifications and the extent of algorithm efficiency; 
2. consider modular implementation;
3. write the code you use repeatedly as a macro, and then, instead of repeating your code, invoke 
the macro;
4. parameterise your code so that it is flexible enough and can be re-used with different parameters;
5. beware: since most of the operations of the SAS macro facility are carried out in the background, 
sometimes debugging them can be fairly mysterious: SAS macros need to be well documented, tested and 
examplified;


For that purpose, we provide hereby some practical recommendations, following also some guidelines 
found in the litterature (see for instance 
[Guidelines for coding of SAS programs](http://www2.sas.com/proceedings/sugi29/258-29.pdf)):

• write code that can be re-used, with different parameters. Keyword parameters are preferable to positional
parameters, because they are less likely to be specified incorrectly.
* all macro variables, unless explicitly `%%global` or macro call arguments, are explicitly `%%local` and 
initialised; in general, avoid using %%global` macro variables;

naming:
* names should be unique, short, and descriptive – in that order of importance
* all macro created temporary variables have unique names (stored as macro values);
* all macro created temporary datasets have unique names (stored as macro values), not interfering with 
others and are explicitly deleted after use (also in case of errors);
* if longer names are needed, underscores may be used to separate words, in order to enhance readability
In order to achieve consistent look and feel and fast code development, we also provide with template code.

parameterising:
* write code that can be re-used, with different parameters; compared to positional parameters, keyword 
parameters are less likely to be specified incorrectly;
* all macro variables, unless explicitly `%%global` or macro call arguments, are explicitly `%%local` and 
initialised; in general, avoid using %%global` macro variables;


1. verify logic of default values of parameters of arguments

6. descriptive heading and user documentation with examples, purpose and verify presence of identifying information: programmer, SAS version, macro version and its date
9. readability, layout of source code and (substantial amount of) comment, and check for grammatical errors and typing errors, especially in comments



READABILITY & APPEARANCE
Separate blocks of code, using indents and white space.
♦ Insert a blank line between SAS program steps; that is, before each `DATA` or `PROC` step.
♦ Be consistent with your indentation increments.
♦ Indent all statements in a logical grouping by the same amount.
♦ Left-justify all OPTIONS, DATA, PROC, and RUN statements. Indent all of the statements within a DATA or
PROC step.
♦ Indent conditional blocks and DO groups, and do it consistently, The logic will be easier to follow.
♦ Align each END statement with its corresponding DO statement. This will make it easier to verify that they
match.
♦ Remember to preface major blocks of code with explanatory comments.
Insert parentheses in meaningful places in order to clarify the sequence in which mathematical or logical
operations are performed,
♦ Break really complicated statements into a number of simpler statements,
make the code easy to read” is “make the physical structure of the code reflect the logical structure

code inside macro definitions is further indented:

Complete systems of macros can be created, where the interrelated set of macros get called within each other, NOT often
using global macro variables to store information created in the outer-level macros and used by the inner macros.
The top-level macro will set up the processing environment subsequently used by the lower-level macros. Values
can often be passed to the inner macros via parameters in the macro calls.

Every macro has a comment header block for built-in documentation (see [page](@ref#mainpage_documenting) on documentation

Template Macro: Macro Setup
In this section of the macro, we do all the pre-execution edit checking and validation, along with displaying standard
debugging information and define the local macro variables used.

Our standard is to set all enumerated (key) values parameter values to upper case. This makes checking of values
easier throughout the rest of the macro code and the upper case values stand out better

We then define and describe local macro variables. While SAS does not require local variable to be defined (with the
%LOCAL statement), it prevents you from accidentally referencing or changing a global variable.

Use comments to explain subsetting or other conditional logic,
♦ Use comments throughout the code to document the program,

checks for values that must always be specified, provides the default value if a parameter is set to
null, checks values for enumerated parameters and will abort the macro if anything serious is detected. Doing this
before the macro starts executing can save significant amounts of machine and user time if an invalid parameter
value was entered.

EFFICIENCY
In summary, to reduce the number of times the data are read:
♦ Minimize the number of passes through the data,
♦ Minimize the number of DATA steps,
♦ Read and store only the data that are needed,
♦ Sort the data only when it is absolutely necessary.

Here are a few more efficiency-related guidelines:
• When you read in an external file, use pointer controls, informats, or column specifications in the INPUT
statement, to read only those fields you actually need.
• Store only the variables you need by using DROP or KEEP statements, DROP= or KEEP= options (eliminate
variables from the output data set which are needed only during DATA step execution, and not afterward).
• When only one condition can be true for a given observation, use IF ... THEN ...ELSE ... statements (or
a SELECT group), instead of a series of IF ... THEN ... statements without ELSE statements (In a
sequence of IF-THEN statements without the ELSE, the SAS System will check each condition for every
observation).
• When using a series of IF ... THEN ... ELSE ... statements, list the conditions in descending order of
probability. This will save CPU time.,
• Use the LENGTH statement to reduce the storage space for variables in SAS data sets.
• Minimize workspace usage by using the DELETE statement in a PROC DATASETS step, to eliminate temporary
data sets that are no longer needed by the program.
• Use the IN operator instead of a series of multiple logical OR operators.

Named vs Positional Parameters
Here's my humble opinion: If a parameter will almost always default to a specific value, make it a named parameter, otherwise make 
it positional. That way one can take advantage of the ability to assign that parameter to a default value when designing the macro
Keyword Parameters allow for a true default value for parameter used by the macro, can be used in any order and finally allow for 
tracing back what was enetered as values for what parameter (think debugging)

TODO?
* set Debug Level Option Parameter. The amount of debugging information required can vary, depending on the problem encountered while
developing or fixing a macro. Currently the debugging parameter G_PING_DEBUG takes two values only (boolean flag)
* Macro Timing (At the start of macro, At important interim steps At the end of macro, with elapsed time.)

Sample Testing Code
Then, after the macro’s %MEND statement, we have some code to help us develop and debug the macro. This code
should be deleted when the final macro is saved to the production macros fileref.

/* http://www.mwsug.org/proceedings/2010/advanced/MWSUG-2010-50.pdf */

<a name="Rprogramming"></a>
### R programming {#Rprogramming}
### R programming