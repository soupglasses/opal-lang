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
\{            : {token, {'{', TokenLoc}}.
\}            : {token, {'}', TokenLoc}}.
\,            : {token, {',', TokenLoc}}.
=             : {token, {'=', TokenLoc}}.
;             : {token, {';', TokenLoc}}.
:             : {token, {':', TokenLoc}}.
\|            : {token, {'|', TokenLoc}}.
->            : {token, {'->', TokenLoc}}.
\|>           : {token, {'|>', TokenLoc}}.
>>=           : {token, {'>>=', TokenLoc}}.

let           : {token, {'let', TokenLoc}}.
fn            : {token, {'fn', TokenLoc}}.
end           : {token, {'end', TokenLoc}}.
do            : {token, {'do', TokenLoc}}.
if            : {token, {'if', TokenLoc}}.
else          : {token, {'else', TokenLoc}}.
yield         : {token, {'yield', TokenLoc}}.
type          : {token, {'type', TokenLoc}}.
is            : {token, {'is', TokenLoc}}.

:ok           : {token, {':ok', TokenLoc}}.
:error        : {token, {':error', TokenLoc}}.

{IDENTIFIER}  : {token, {identifier, TokenLoc, list_to_atom(TokenChars)}}.

Erlang code.
