%% Terminals
Terminals     
    int float
    '+' '-' '*' '/' '(' ')' ','
    identifier '=' ';' 'let' 
    'fn' 'end' 'do' 'if' 'else'.

%% Nonterminals
Nonterminals
    program
    statements statement
    expr
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
statement -> block : '$1'.

% Expression grammar using precedence
expr -> expr '+' expr : {add, '$1', '$3'}.
expr -> expr '-' expr : {subtract, '$1', '$3'}.
expr -> expr '*' expr : {multiply, '$1', '$3'}.
expr -> expr '/' expr : {divide, '$1', '$3'}.
expr -> int : {int, unwrap('$1')}.
expr -> float : {float, unwrap('$1')}.
expr -> identifier : {var, unwrap('$1')}.
expr -> '(' expr ')' : '$2'.
expr -> function_call : '$1'.

assignment -> identifier '=' expr : {assign, unwrap('$1'), '$3'}.
definition -> 'let' identifier '=' expr : {def, unwrap('$2'), '$4'}.

% Function definition with "fn name do ... end" syntax
function_def -> 'fn' identifier 'do' statements 'end' :
                {fn_def, unwrap('$2'), [], {block, '$4'}}.
function_def -> 'fn' identifier '(' ')' 'do' statements 'end' :
                {fn_def, unwrap('$2'), [], {block, '$6'}}.
function_def -> 'fn' identifier '(' param_list ')' 'do' statements 'end' :
                {fn_def, unwrap('$2'), '$4', {block, '$7'}}.

function_call -> identifier '(' ')' : {call, unwrap('$1'), []}.
function_call -> identifier '(' param_list ')' : {call, unwrap('$1'), '$3'}.

param_list -> identifier : [unwrap('$1')].
param_list -> param_list ',' identifier : append_param('$1', unwrap('$3')).

block -> 'do' statements 'end' : {block, '$2'}.

statement -> 'if' expr 'do' statements 'end' : {if_stmt, '$2', {block, '$4'}, {block, []}}.
statement -> 'if' expr 'do' statements 'else' statements 'end' : {if_stmt, '$2', {block, '$4'}, {block, '$6'}}.

Erlang code.

unwrap({_, _, Value}) -> Value.

%helper for param
append_param(List, Param) -> List ++ [Param].