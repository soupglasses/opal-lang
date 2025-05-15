Definitions.
INT        = 0|[1-9][0-9\_]*
FLOAT      = [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
IDENTIFIER = [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE = [\s\t]
NEWLINE    = \n|\r|\r\n
COMMENT    = #.*

Rules.
{INT}         : {token, token({int, TokenLoc, list_to_integer(clean_underscores(TokenChars))})}.
{FLOAT}       : {token, token({float, TokenLoc, list_to_float(clean_underscores(TokenChars))})}.
{IDENTIFIER}  : {token, token({identifier, TokenLoc, list_to_atom(TokenChars)})}.
\=            : {token, token({'=', TokenLoc})}.
\;            : {token, token({';', TokenLoc})}.
\,            : {token, token({',', TokenLoc})}.
\+            : {token, token({'+', TokenLoc})}.
\-            : {token, token({'-', TokenLoc})}.
\*            : {token, token({'*', TokenLoc})}.
\/            : {token, token({'/', TokenLoc})}.
\(            : {token, token({'(', TokenLoc})}.
\)            : {token, token({')', TokenLoc})}.
{WHITESPACE}+ : skip_token.
{NEWLINE}     : process_newline(TokenLoc).
{COMMENT}     : skip_token.

Erlang code.

clean_underscores(Str) when is_list(Str) ->
    [C || C <- Str, C =/= $_].

process_newline(TokenLoc) ->
    PrevTokenType = case get(prev_token_type) of
        undefined -> none;
        Type -> Type
    end,
    
    NeedSemicolon = lists:member(PrevTokenType, [identifier, ')']),
    
    if 
        NeedSemicolon ->
            put(prev_token_type, ';'),
            {token, {';', TokenLoc}};
        true ->
            skip_token
    end.

token(Token) ->
    update_token_history(Token),
    Token.

update_token_history({TokenType, _}) ->
    put(prev_token_type, TokenType);
update_token_history({TokenType, _, _}) ->
    put(prev_token_type, TokenType).