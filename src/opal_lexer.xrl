Definitions.

% Whitespace
WS   = [\s\t\r\n]

% Identifiers and atoms
UPPER_LETTER = [A-Z]
LOWER_LETTER = [a-z]
LETTER       = [a-zA-Z]
MODULE_ID    = {UPPER_LETTER}({LETTER}|{DIGIT}|_)*
IDENTIFIER   = {LOWER_LETTER}({LETTER}|{DIGIT}|_)*
ATOM         = :{IDENTIFIER}

% Numbers
INTEGER    = 0|[1-9][0-9\_]*
FLOAT      = [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
%STRING = 
CHAR = \?.

COMMENT    = #.*\n?

Rules.

% Keywords
module      : {token, {module, TokenLoc}}.
do          : {token, {do, TokenLoc}}.
end         : {token, {'end', TokenLoc}}.
fn          : {token, {fn, TokenLoc}}.
import      : {token, {import, TokenLoc}}.
if          : {token, {'if', TokenLoc}}.
then        : {token, {then, TokenLoc}}.
else        : {token, {'else', TokenLoc}}.
while       : {token, {while, TokenLoc}}.
not         : {token, {'not', TokenLoc}}.
true        : {token, {bool, TokenLoc, true}}.
false       : {token, {bool, TokenLoc, false}}.


% Operators
\+          : {token, {'+', TokenLoc}}.
-           : {token, {'-', TokenLoc}}.
\*          : {token, {'*', TokenLoc}}.
/           : {token, {'/', TokenLoc}}.
\%          : {token, {'%', TokenLoc}}.
\^          : {token, {'^', TokenLoc}}.
>=          : {token, {'>=', TokenLoc}}.
<=          : {token, {'<=', TokenLoc}}.
!=          : {token, {'!=', TokenLoc}}.
==          : {token, {'==', TokenLoc}}.
<           : {token, {'<', TokenLoc}}.
>           : {token, {'>', TokenLoc}}.
=           : {token, {'=', TokenLoc}}.

% Delimiters
\(              : {token, {'(', TokenLoc}}.
\)              : {token, {')', TokenLoc}}.
\[              : {token, {'[', TokenLoc}}.
\]              : {token, {']', TokenLoc}}.
,               : {token, {',', TokenLoc}}.
\|              : {token, {'|', TokenLoc}}.
\.              : {token, {'.', TokenLoc}}.
;               : {token, {';', TokenLoc}}.

% Literals
{INTEGER}     : {token, {int, TokenLoc, list_to_integer(clean_underscores(TokenChars))}}.
{FLOAT}       : {token, {float, TokenLoc, list_to_float(clean_underscores(TokenChars))}}.
%{STRING}     : {token, {string, TokenLoc, extract_string(TokenChars)}}.
{CHAR}        : {token, {char, TokenLoc, list_to_atom(tl(TokenChars))}}.
{ATOM}        : {token, {atom, TokenLoc, list_to_atom(tl(TokenChars))}}.
{MODULE_ID}   : {token, {module_id, TokenLoc, list_to_atom(TokenChars)}}.
{IDENTIFIER}  : {token, {var, TokenLoc, list_to_atom(TokenChars)}}.

% Whitespace and newlines
{WS}+          : skip_token.
{COMMENT}      : skip_token.

Erlang code.

clean_underscores(Str) when is_list(Str) ->
    [C || C <- Str, C =/= $_].
