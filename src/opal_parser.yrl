Nonterminals
program module_def module_blocks module_block
statements statement patterns patterns_ pattern
args args_ arg expr bop uop literal.

Terminals
'module' 'do' 'end' 'fn' 'import'
'if' 'then' 'else' 'while' 'not' 'and' 'or'
'+' '-' '*' '/' '%' '^' '>=' '<=' '!=' '==' '<' '>' '='
'(' ')' '[' ']' ',' ';' '|' '.'
int float string char atom var bool
module_id.

Rootsymbol program.

% Operator precedence
Left     100 '|'.
Left     200 'and'.
Left     200 'or'.
Nonassoc 300 '=='.
Nonassoc 300 '!='.
Nonassoc 300 '<'.
Nonassoc 300 '>'.
Nonassoc 300 '<='.
Nonassoc 300 '>='.
Left  500 '+'.
Left  500 '-'.
Left  600 '*'.
Left  600 '/'.
Left  600 '%'.
Right 700 '^'.
Unary 800 uop.

program -> module_def : '$1'.
program -> module_blocks : '$1'.

module_def -> 'module' module_id 'do' module_blocks 'end' :
    {module, pos('$1'), {'$2', '$4'}}.

module_blocks -> module_block : ['$1'].
module_blocks -> module_block module_blocks : ['$1' | '$2'].

module_block -> 'fn' var '(' ')' 'do' statements 'end' :
    {function, pos('$1'), {'$2', {pattern, []}, '$6'}}.
module_block -> 'fn' var '(' patterns ')' 'do' statements 'end' :
    {function, pos('$1'), {'$2', '$4', '$7'}}.
module_block -> statements : '$1'.

statements -> statement : ['$1'].
statements -> statement ';' statements : ['$1' | '$3'].

statement -> 'if' expr 'then' statements 'else' statements 'end' :
    {'if', pos('$2'), {'$2', '$4', '$6'}}.
statement -> 'while' expr 'do' statements 'end' :
    {while, pos('$2'), {'$2', '$4'}}.
statement -> patterns '=' expr :
    {'$2', '$1', '$3'}.
statement -> expr :
    '$1'.

patterns -> patterns_ : {pattern, '$1'}.
patterns_ -> pattern : ['$1'].
patterns_ -> pattern ',' patterns_ : ['$1' | '$3'].

pattern -> literal : '$1'.
%pattern -> '[' literal '|' pattern ']' :
%    {list_pattern, pos('$2'), {'$2', '$4'}}.

args -> args_ : {args, '$1'}.
args_ -> arg : ['$1'].
args_ -> arg ',' args_ : ['$1' | '$3'].

arg -> expr : '$1'.

expr -> literal : '$1'.
expr -> expr bop expr : {'$2', '$1', '$3'}.
expr -> uop expr : {'$1', '$2'}.
expr -> var '(' ')' :
    {apply, pos('$1') , {'$1', {args, []}}}.
expr -> var '(' args ')' :
    {apply, pos('$1') , {'$1', '$3'}}.
expr -> atom '.' var '(' ')' :
    {call, pos('$1') , {'$1', '$3', {args, []}}}.
expr -> atom '.' var '(' args ')' :
    {call, pos('$1'), {'$1', '$3', '$5'}}.
expr -> '(' expr ')' : '$2'.

bop -> 'and' : '$1'.
bop -> 'or' : '$1'.
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

pos({_Token, Pos, _Value}) -> Pos;
pos({_Token, Pos}) -> Pos.
