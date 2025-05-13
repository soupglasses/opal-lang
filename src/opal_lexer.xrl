Definitions.

INT        = [0-9]+
FLOAT      = [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
IDENTIFIER = [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE = [\s\t\n\r]
COMMENT    = #.*

Rules.

{INT}         : {token, {int, TokenLoc, list_to_integer(TokenChars)}}.
{FLOAT}       : {token, {float, TokenLoc, list_to_float(TokenChars)}}.
{IDENTIFIER}  : {token, {identifier, TokenLoc, list_to_atom(TokenChars)}}.
\=            : {token, {'=', TokenLoc}}.
\;            : {token, {';', TokenLoc}}.
\+            : {token, {'+', TokenLoc}}.
\-            : {token, {'-', TokenLoc}}.
\*            : {token, {'*', TokenLoc}}.
\/            : {token, {'/', TokenLoc}}.
\(            : {token, {'(', TokenLoc}}.
\)            : {token, {')', TokenLoc}}.
{WHITESPACE}+ : skip_token.
{COMMENT}     : skip_token.
%.             : {error, {illegal, TokenLoc, TokenChars}}.

Erlang code.
