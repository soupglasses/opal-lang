Nonterminals
program module_def module_blocks module_block
statements statement patterns pattern_items pattern
fun_call
expr_list list_expr tuple_expr
expr uop literal.

Terminals
'module' 'do' 'end' 'fn'
'if' 'then' 'else' 'while' 'not' 'and' 'or'
'+' '-' '*' '/' '%' '^' '>=' '<=' '!=' '==' '<' '>' '='
'(' ')' '[' ']' '{' '}' '|' ',' ';' '.'
int float string char atom var bool nil
module_id.

Rootsymbol program.

% Operator precedence
Left     200 'and'.
Left     200 'or'.
Nonassoc 300 '=='.
Nonassoc 300 '!='.
Nonassoc 300 '<'.
Nonassoc 300 '>'.
Nonassoc 300 '<='.
Nonassoc 300 '>='.
Left     500 '+'.
Left     500 '-'.
Left     600 '*'.
Left     600 '/'.
Left     600 '%'.
Right    700 '^'.
Unary    800 uop.
Right    900 '('.  % Give function calls higher precedence

program -> module_def : '$1'.
program -> module_blocks : '$1'.

module_def -> 'module' module_id 'do' module_blocks 'end' :
    {module, pos('$1'), {'$2', '$4'}}.

module_blocks -> module_block : ['$1'].
module_blocks -> module_block module_blocks : ['$1' | '$2'].

module_block -> 'fn' var '(' ')' 'do' statements 'end' :
    {function, pos('$1'), {'$2', {patterns, []}, '$6'}}.
module_block -> 'fn' var '(' patterns ')' 'do' statements 'end' :
    {function, pos('$1'), {'$2', '$4', '$7'}}.
module_block -> statements : '$1'.

statements -> statement : ['$1'].
statements -> statement ';' statements : ['$1' | '$3'].

statement -> 'if' expr 'then' statements 'else' statements 'end' :
    {'if', pos('$1'), {'$2', '$4', '$6'}}.
statement -> 'while' expr 'do' statements 'end' :
    {while, pos('$2'), {'$2', '$4'}}.
statement -> pattern '=' expr :
    {'$2', '$1', '$3'}.
statement -> expr :
    '$1'.

patterns -> pattern_items : {patterns, '$1'}.
pattern_items -> pattern : ['$1'].
pattern_items -> pattern ',' pattern_items : ['$1' | '$3'].

pattern -> expr : convert_to_pattern('$1').

% Local call
fun_call -> var '(' ')' :
    {apply, pos('$1') , {'$1', []}}.
fun_call -> var '(' expr_list ')' :
    {apply, pos('$1') , {'$1', '$3'}}.
% Remote call
fun_call -> atom '.' var '(' ')' :
    {call, pos('$1') , {'$1', '$3', []}}.
fun_call -> atom '.' var '(' expr_list ')' :
    {call, pos('$1'), {'$1', '$3', '$5'}}.

% Generic comma-seperated list of expressions.
expr_list -> expr : ['$1'].
expr_list -> expr ',' expr_list : ['$1' | '$3'].

% List Expressions
list_expr -> '[' ']' : {list, []}.
list_expr -> '[' expr_list ']' : build_list_cons('$2').
list_expr -> '[' expr_list '|' expr ']' : build_list_cons(lists:append('$2', '$4')).

% Tuple Expressions
tuple_expr -> '{' '}' : {tuple, []}.
tuple_expr -> '{' expr_list '}' : {tuple, '$2'}.

expr -> fun_call : '$1'.
expr -> list_expr : '$1'.
expr -> tuple_expr : '$1'.
expr -> '(' expr ')' : '$2'.
expr -> uop expr : {'$1', '$2'}.
expr -> expr 'and' expr : {'$2', '$1', '$3'}.
expr -> expr 'or' expr : {'$2', '$1', '$3'}.
expr -> expr '==' expr : {'$2', '$1', '$3'}.
expr -> expr '!=' expr : {'$2', '$1', '$3'}.
expr -> expr '<' expr : {'$2', '$1', '$3'}.
expr -> expr '>' expr : {'$2', '$1', '$3'}.
expr -> expr '<=' expr : {'$2', '$1', '$3'}.
expr -> expr '>=' expr : {'$2', '$1', '$3'}.
expr -> expr '+' expr : {'$2', '$1', '$3'}.
expr -> expr '-' expr : {'$2', '$1', '$3'}.
expr -> expr '*' expr : {'$2', '$1', '$3'}.
expr -> expr '/' expr : {'$2', '$1', '$3'}.
expr -> expr '%' expr : {'$2', '$1', '$3'}.
expr -> expr '^' expr : {'$2', '$1', '$3'}.
expr -> literal : '$1'.

uop -> 'not' : '$1'.
uop -> '-' : '$1'.

literal -> bool : '$1'.
literal -> int : '$1'.
literal -> float : '$1'.
literal -> var : '$1'.
literal -> atom : '$1'.
literal -> char : '$1'.
literal -> string : '$1'.
literal -> nil : '$1'.

Erlang code.

build_list_cons([H | T]) ->
    {list_cons, {H, build_list_cons(T)}};
build_list_cons([]) ->
    {list, []};
build_list_cons(E) ->
    E.

pos({_Token, Pos, _Value}) -> Pos;
pos({_Token, Pos}) -> Pos.

convert_to_pattern(Expr) ->
    case Expr of
        % Convert list expressions to list patterns.
        {list_cons, {Head, Tail}} -> 
            {list_cons, {convert_to_pattern(Head), convert_to_pattern(Tail)}};
        % Convert tuple expressions to tuple patterns.
        {tuple, Elements} -> {tuple, [convert_to_pattern(E) || E <- Elements]};
        % For simple literal tokens without nesting.
        Token when is_tuple(Token) ->
            case element(1, Token) of
                bool -> Token;
                int -> Token;
                float -> Token;
                var -> Token;
                atom -> Token;
                char -> Token;
                string -> Token;
                nil -> Token;
                list -> Token;
                _ -> error({invalid_pattern, Token})
            end;
        _ -> error({invalid_pattern, Expr})
    end.
