%% Terminals
Terminals
    int float
    '+' '-' '*' '/' '(' ')' 
    identifier '=' ';' 'let' '{' '}'
    'fn' '->' 'end'.

%% Nonterminals
Nonterminals
    program
    statements statement
    expr term factor
    assignment definition
    function_def function_call
    param_list
    block.

Rootsymbol program.

%% Operator precedence
Left 100 '+' '-'.
Left 200 '*' '/'.

%% Grammar rules
program -> statements : '$1'.

statements -> statement : ['$1'].
statements -> statement ';' statements : ['$1' | '$3'].

statement -> expr : '$1'.
statement -> assignment : '$1'.
statement -> definition : '$1'.
statement -> function_def : '$1'.
statement -> function_call : '$1'.
statement -> block : '$1'.

expr -> term : '$1'.
term -> factor : '$1'.
term -> term '+' factor : {add, '$1', '$3'}.
term -> term '-' factor : {subtract, '$1', '$3'}.
factor -> int : {int, unwrap('$1')}.
factor -> float : {float, unwrap('$1')}.
factor -> identifier : {var, unwrap('$1')}.
factor -> '(' expr ')' : '$2'.
factor -> factor '*' factor : {multiply, '$1', '$3'}.
factor -> factor '/' factor : {divide, '$1', '$3'}.

assignment -> identifier '=' expr : {assign, unwrap('$1'), '$3'}.
definition -> 'let' identifier '=' expr : {def, unwrap('$2'), '$4'}.

function_def -> 'fn' identifier '(' ')' '->' expr 'end' :
                {fn_def, unwrap('$2'), [], '$6'}.
function_def -> 'fn' identifier '(' param_list ')' '->' expr 'end' :
                {fn_def, unwrap('$2'), '$4', '$7'}.

function_call -> identifier '(' ')' : {call, unwrap('$1'), []}.
function_call -> identifier '(' param_list ')' : {call, unwrap('$1'), '$3'}.

param_list -> param_list ',' identifier : '$1' ++ [unwrap('$3')].
param_list -> identifier : [unwrap('$1')].

block -> '{' statements '}' : {block, '$2'}.

%% Erlang code
Erlang code.
unwrap({, _, Value}) -> Value.
