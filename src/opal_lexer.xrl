Definitions.

INT        = 0|[1-9][0-9\_]*
FLOAT      = [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
IDENTIFIER = [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE = [\s\t]
NEWLINE    = \n|\r|\r\n
COMMENT    = #.*

Rules.

{INT}         : {token, {int, TokenLoc, list_to_integer(clean_underscores(TokenChars))}}.
{FLOAT}       : {token, {float, TokenLoc, list_to_float(clean_underscores(TokenChars))}}.
{IDENTIFIER}  : {token, {identifier, TokenLoc, list_to_atom(TokenChars)}}.
\=            : {token, {'=', TokenLoc}}.
\;            : {token, {';', TokenLoc}}.
\,            : {token, {',', TokenLoc}}.
\+            : {token, {'+', TokenLoc}}.
\-            : {token, {'-', TokenLoc}}.
\*            : {token, {'*', TokenLoc}}.
\/            : {token, {'/', TokenLoc}}.
\(            : {token, {'(', TokenLoc}}.
\)            : {token, {')', TokenLoc}}.
{WHITESPACE}+ : skip_token.
{NEWLINE}     : process_newline(TokenLoc).
{COMMENT}     : skip_token.
%.             : {error, {illegal, TokenLoc, TokenChars}}.

Erlang code.

clean_underscores(Str) when is_list(Str) ->
    [C || C <- Str, C =/= $_].

process_newline(TokenLoc) ->
    {token, {newline, TokenLoc}}.
