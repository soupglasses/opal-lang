Definitions.
INT        = [0-9]+
FLOAT      = [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
WHITESPACE = [\s\t\n\r]
IDENTIFIER = [a-zA-Z_][a-zA-Z0-9_]*

Rules.
{INT}         : {token, {int, TokenLoc, list_to_integer(TokenChars)}}.
{FLOAT}       : {token, {float, TokenLoc, list_to_float(TokenChars)}}.
{WHITESPACE}+ : skip_token.
\+            : {token, {'+', TokenLoc}}.
\-            : {token, {'-', TokenLoc}}.
\*            : {token, {'*', TokenLoc}}.
\/            : {token, {'/', TokenLoc}}.
\(            : {token, {'(', TokenLoc}}.
\)            : {token, {')', TokenLoc}}.
%.             : {error, {illegal, TokenLoc, TokenChars}}.



{IDENTIFIER}  : {token, {identifier, TokenLoc, list_to_atom(TokenChars)}}.

Erlang code.
