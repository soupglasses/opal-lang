Terminals int float identifier '+' '-' '*' '/' '(' ')' '=' ';' ','.

Nonterminals program statements statement patterns pattern expr.

% Operator precedence
Left 100 '+' '-'.
Left 200 '*' '/'.

Rootsymbol program.

%% Entry point
program -> statements : '$1'.

%% Statements
statements -> statement : ['$1' | []].
statements -> statement ';' statements : ['$1' | '$3'].

statement -> expr : '$1'.
statement -> pattern '=' expr ';' statement : {match, '$1', '$3', '$5'}.

%% Pattern Matching
patterns -> pattern ',' patterns : ['$1' | '$3'].
patterns -> pattern : ['$1'].

pattern -> identifier : {var, pos('$1'), unwrap('$1')}.

%% Expressions
expr -> '(' expr ')'  : '$2'.
expr -> expr '+' expr : {add, '$1', '$3'}.
expr -> expr '-' expr : {subtract, '$1', '$3'}.
expr -> expr '*' expr : {multiply, '$1', '$3'}.
expr -> expr '/' expr : {divide, '$1', '$3'}.
expr -> int           : {int, pos('$1'), unwrap('$1')}.
expr -> float         : {float, pos('$1'), unwrap('$1')}.
expr -> identifier    : {var, pos('$1'), unwrap('$1')}.

Erlang code.

unwrap({_Token, _Pos, Value}) -> Value.
pos({_Token, Pos, _Value}) -> Pos.
