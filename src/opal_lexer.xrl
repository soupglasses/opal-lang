Definitions.
INT        = 0|[1-9][0-9\_]*
FLOAT      = [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
IDENTIFIER = [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE = [\s\t]
NEWLINE    = \n|\r|\r\n
COMMENT    = #.*

Rules.
{INT}         : {token, {int, TokenLine, list_to_integer(clean_underscores(TokenChars))}}.
{FLOAT}       : {token, {float, TokenLine, list_to_float(clean_underscores(TokenChars))}}.
{IDENTIFIER}  : {token, {identifier, TokenLine, list_to_atom(TokenChars)}}.
\=            : {token, {'=', TokenLine}}.
\;            : {token, {';', TokenLine}}.
\,            : {token, {',', TokenLine}}.
\+            : {token, {'+', TokenLine}}.
\-            : {token, {'-', TokenLine}}.
\*            : {token, {'*', TokenLine}}.
\/            : {token, {'/', TokenLine}}.
\(            : {token, {'(', TokenLine}}.
\)            : {token, {')', TokenLine}}.
{WHITESPACE}+ : skip_token.
{NEWLINE}     : {token, handle_newline(TokenLine)}.
{COMMENT}     : skip_token.
%.             : {error, {illegal, TokenLine, TokenChars}}.

Erlang code.

-export([clean_prev_token/0]).

clean_underscores(Str) when is_list(Str) ->
    [C || C <- Str, C =/= $_].


clean_prev_token() ->
    erase(prev_token).


handle_newline({Line, Col} = TokenLoc) ->
    PrevToken = get(prev_token),
    case should_insert_semicolon(PrevToken) of
        true -> {token, {';', TokenLoc}};
        false -> {token, {'newline', TokenLoc}}
    end;
handle_newline(Line) when is_integer(Line) ->
    handle_newline({Line, 0}).



should_insert_semicolon(undefined) ->
    false;
should_insert_semicolon({Type, _, _}) when Type =:= int; Type =:= float; Type =:= identifier ->
    true;
should_insert_semicolon({')', _}) ->
    true;
should_insert_semicolon({Op, _}) when Op =:= '+'; Op =:= '-'; Op =:= '*'; Op =:= '/';
                        Op =:= '='; Op =:= '('; Op =:= ','; Op =:= ';' ->
    false;
should_insert_semicolon(_) ->
    false.

token(Token) ->
    put(prev_token, Token),
    Token.