Nonterminals
program module_def module_blocks module_block
statements statement patterns pattern
expr expr_list bop uop literal.

Terminals
'module' 'do' 'end' 'fn' 'import'
'if' 'then' 'else' 'while' 'not'
'+' '-' '*' '/' '%' '^' '>=' '<=' '!=' '==' '<' '>' '='
'(' ')' '[' ']' ',' ';' '|' '.'
int float string char atom var bool
module_id.

Rootsymbol program.

% Operator precedence
Left  200 '|'.
Left  300 '=='.
Left  300 '!='.
Left  400 '<'.
Left  400 '>'.
Left  400 '<='.
Left  400 '>='.
Left  500 '+'.
Left  500 '-'.
Left  600 '*'.
Left  600 '/'.
Left  600 '%'.
Right 700 '^'.
Unary 800 uop.

program -> module_def : '$1'.
program -> module_block : '$1'.
program -> expr : '$1'.

module_def -> 'module' module_id 'do' module_blocks 'end' :
    {module, pos('$1'), {'$2', '$4'}}.

module_blocks -> module_block : ['$1'].
module_blocks -> module_block module_blocks : ['$1' | '$2'].

module_block -> 'fn' var '(' ')' 'do' statements 'end' :
    {function, pos('$1'), {'$2', [], '$6'}}.
module_block -> 'fn' var '(' patterns ')' 'do' statements 'end' :
    {function, pos('$1'), {'$2', '$4', '$7'}}.

statements -> statement : ['$1'].
statements -> statement ';' statements : ['$1' | '$3'].

statement -> 'if' expr 'then' statements 'else' statements 'end' :
    {'if', pos('$2'), {'$2', '$4', '$6'}}.
statement -> 'while' expr 'do' statements 'end' :
    {while, pos('$2'), {'$2', '$4'}}.
statement -> pattern '=' expr :
    {assign, '$1', '$3'}.
statement -> expr :
    '$1'.

patterns -> pattern : ['$1'].
patterns -> pattern ',' patterns : ['$1' | '$3'].

pattern -> literal :
    '$1'.
pattern -> '[' literal '|' pattern ']' :
    {list_pattern, pos('$2'), {'$2', '$4'}}.

expr -> literal : '$1'.
expr -> expr bop expr : {'$2', '$1', '$3'}.
expr -> uop expr : {'$1', '$2'}.
expr -> atom '.' var '(' ')' :
    {external_call, pos('$3') , {'$1', '$3', []}}.
%expr -> atom '.' function_id '(' expr_list ')' :
%    {external_call, pos('$3'), {'$1', '$3', '$5'}}.
expr -> '(' expr ')' : '$2'.

bop -> '+' : '$1'.
bop -> '-' : '$1'.
bop -> '*' : '$1'.
bop -> '/' : '$1'.
bop -> '%' : '$1'.
bop -> '^' : '$1'.
bop -> '>=' : '$1'.
bop -> '<=' : '$1'.
bop -> '!=' : '$1'.
bop -> '==' : '$1'.
bop -> '<' : '$1'.
bop -> '>' : '$1'.

uop -> 'not' : '$1'.
uop -> '-' : '$1'.

literal -> bool : '$1'.
literal -> int : '$1'.
literal -> float : '$1'.
literal -> var : '$1'.
literal -> atom : '$1'.
literal -> char : '$1'.
%literal -> string : '$1'.
%literal -> list_expr : '$1'.

Erlang code.

unwrap({_Token, _Pos, Value}) -> Value.
pos({_Token, Pos, _Value}) -> Pos;
pos({_Token, Pos}) -> Pos.
