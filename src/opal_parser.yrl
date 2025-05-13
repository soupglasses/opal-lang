Terminals int float identifier '+' '-' '*' '/' '(' ')' '=' ';'.

Nonterminals program statements statement expr id.

% Operator precedence
Left 100 '+' '-'.
Left 200 '*' '/'.

Rootsymbol program.

program -> statements : '$1'.

% List based:
statements -> statement : ['$1' | []].
statements -> statement ';' statements : ['$1' | '$3'].

statement -> expr : '$1'.
statement -> id '=' expr ';' statement: {match, '$1', '$3', '$5'}.

expr -> '(' expr ')' : '$2'.
expr -> expr '+' expr : {add, '$1', '$3'}.
expr -> expr '-' expr : {subtract, '$1', '$3'}.
expr -> expr '*' expr : {multiply, '$1', '$3'}.
expr -> expr '/' expr : {divide, '$1', '$3'}.
expr -> int : {int, unwrap('$1')}.
expr -> float : {float, unwrap('$1')}.
expr -> id : '$1'.

id -> identifier : {identifier, unwrap('$1')}.

Erlang code.

unwrap({_Token, _Pos, Value}) -> Value.
