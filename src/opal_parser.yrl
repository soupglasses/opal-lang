Terminals int float '+' '-' '*' '/' '(' ')'
identifier '=' ';' 'let' '{' '}'.

Nonterminals program statements statement expr assignment definition block.

% Operator precedence
Left 100 '+' '-'.
Left 200 '*' '/'.

Rootsymbol program.

program -> statement : '$1'.

statement -> expr : '$1'.

expr -> '(' expr ')' : '$2'.
expr -> expr '+' expr : {add, '$1', '$3'}.
expr -> expr '-' expr : {subtract, '$1', '$3'}.
expr -> expr '*' expr : {multiply, '$1', '$3'}.
expr -> expr '/' expr : {divide, '$1', '$3'}.
expr -> int : {int, unwrap('$1')}.
expr -> float : {float, unwrap('$1')}.

assignment -> identifier '=' expr : {assign, unwrap('$1'), '$3'}.
definition -> 'let' identifier '=' expr : {def, unwrap('$2'), '$4'}.
block -> '{' statements '}' : {block, '$2'}.

Erlang code.

unwrap({_Token, _Pos, Value}) -> Value.
