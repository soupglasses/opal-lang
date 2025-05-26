module 'opal_evaluator' ['eval'/2, 'inspect_ast'/1]
    attributes []

%% Main evaluation function - public interface
'eval'/2 =
    fun (Ast, Env) ->
        try
            case apply 'do_eval'/2 (Ast, Env) of
                {Value, NewEnv} -> {'ok', Value, NewEnv}
            end
        of
            <Result> -> Result
        catch
            <'error', {'runtime_error', Message}> ->
                {'error', Message}
            <'error', _> ->
                {'error', <<"Evaluation error">>}
        end

%% For debugging during development
'inspect_ast'/1 =
    fun (Ast) ->
        let IoPrintFun = 
            fun () ->
                call 'io':'format'
                    (<<"AST structure: ~p~n">>, [Ast])
            end
        in
            do IoPrintFun ()
               Ast

%% Handle basic literals
'do_eval'/2 =
    fun ({'int', Value}, Env) ->
            {Value, Env}
        ({'float', Value}, Env) ->
            {Value, Env}
        
        %% Handle arithmetic expressions
        ({'add', Left, Right}, Env) ->
            let {LeftVal, Env1} = apply 'do_eval'/2 (Left, Env)
                {RightVal, Env2} = apply 'do_eval'/2 (Right, Env1)
            in
                {LeftVal + RightVal, Env2}
        
        ({'subtract', Left, Right}, Env) ->
            let {LeftVal, Env1} = apply 'do_eval'/2 (Left, Env)
                {RightVal, Env2} = apply 'do_eval'/2 (Right, Env1)
            in
                {LeftVal - RightVal, Env2}
        
        ({'multiply', Left, Right}, Env) ->
            let {LeftVal, Env1} = apply 'do_eval'/2 (Left, Env)
                {RightVal, Env2} = apply 'do_eval'/2 (Right, Env1)
            in
                {LeftVal * RightVal, Env2}
        
        ({'divide', Left, Right}, Env) ->
            let {LeftVal, Env1} = apply 'do_eval'/2 (Left, Env)
                {RightVal, Env2} = apply 'do_eval'/2 (Right, Env1)
            in
                case RightVal of
                    <0> -> primop 'error' ({'runtime_error', <<"Division by zero">>})
                    <_> -> {LeftVal / RightVal, Env2}
                end
        
        %% Variable reference
        ({'var', Name}, Env) ->
            case call 'opal_environment':'lookup' (Env, Name) of
                {'ok', Value} -> {Value, Env}
                {'error', 'undefined_variable'} ->
                    let Msg = call 'lists':'concat' ([<<"Undefined variable: ">>, Name])
                    in primop 'error' ({'runtime_error', Msg})
            end
        
        %% Variable definition
        ({'def', Name, Expr}, Env) ->
            let {Value, Env1} = apply 'do_eval'/2 (Expr, Env)
                NewEnv = call 'opal_environment':'define' (Env1, Name, Value)
            in
                {Value, NewEnv}
        
        %% Variable assignment
        ({'assign', Name, Expr}, Env) ->
            let {Value, Env1} = apply 'do_eval'/2 (Expr, Env)
                NewEnv = call 'opal_environment':'define' (Env1, Name, Value)
            in
                {Value, NewEnv}
        
        %% Block of expressions with new scope
        ({'block', Exprs}, Env) ->
            let BlockEnv = call 'opal_environment':'extend' (Env)
                ReduceFun = fun (Expr, {_, AccEnv}) ->
                    apply 'do_eval'/2 (Expr, AccEnv)
                {Result, _FinalBlockEnv} = call 'lists':'foldl' (ReduceFun, {'nil', BlockEnv}, Exprs)
            in
                {Result, Env}
        
        %% Block of expressions without new scope
        ({'seq', Exprs}, Env) ->
            let ReduceFun = fun (Expr, {_, AccEnv}) ->
                    apply 'do_eval'/2 (Expr, AccEnv)
            in
                call 'lists':'foldl' (ReduceFun, {'nil', Env}, Exprs)
        
        %% Function definition
        ({'fn_def', Name, Params, Body}, Env) ->
            let FnValue = {'function', Params, Body, Env}
                NewEnv = call 'opal_environment':'define' (Env, Name, FnValue)
            in
                {FnValue, NewEnv}
        
        %% Function application/call
        ({'call', Name, Args}, Env) ->
            let ProcessedArgs = call 'lists':'map' (
                    fun (Arg) ->
                        case Arg of
                            <N> when call 'erlang':'is_number' (N) -> {'int', N}
                            <A> -> A
                        end
                    end, Args)
            in
                case call 'opal_environment':'lookup' (Env, Name) of
                    {'ok', {'function', Params, Body, ClosureEnv}} ->
                        let EvalArgsFun = fun (Arg, {Values, E}) ->
                                let {Val, E1} = apply 'do_eval'/2 (Arg, E)
                                in {call 'lists':'append' (Values, [Val]), E1}
                            {ArgValues, NewEnv} = call 'lists':'foldl' (EvalArgsFun, {[], Env}, ProcessedArgs)
                            
                            ExtendedEnv = call 'opal_environment':'extend' (ClosureEnv)
                            ZipFun = fun ({Param, Value}, Acc) ->
                                call 'opal_environment':'define' (Acc, Param, Value)
                            ParamValuePairs = call 'lists':'zip' (Params, ArgValues)
                            CallEnv = call 'lists':'foldl' (ZipFun, ExtendedEnv, ParamValuePairs)
                            
                            {Result, _} = apply 'do_eval'/2 (Body, CallEnv)
                        in
                            {Result, NewEnv}
                    
                    {'ok', _NonFunction} ->
                        let Msg = call 'lists':'concat' ([Name, <<" is not a function">>])
                        in primop 'error' ({'runtime_error', Msg})
                    
                    {'error', 'undefined_variable'} ->
                        let Msg = call 'lists':'concat' ([<<"Undefined function: ">>, Name])
                        in primop 'error' ({'runtime_error', Msg})
                end
        
        %% Pipe operator
        ({'pipe', Left, Right}, Env) ->
            let {LeftVal, Env1} = apply 'do_eval'/2 (Left, Env)
            in
                case Right of
                    {'var', FnName} ->
                        apply 'do_eval'/2 ({'call', FnName, [LeftVal]}, Env1)
                    <_> ->
                        primop 'error' ({'runtime_error', <<"Right side of |> must be a function reference">>})
                end
        
        %% Result types
        ({'ok_result', Value}, Env) ->
            let {Val, NewEnv} = apply 'do_eval'/2 (Value, Env)
            in {{'ok', Val}, NewEnv}
        
        ({'error_result', Value}, Env) ->
            let {Val, NewEnv} = apply 'do_eval'/2 (Value, Env)
            in {{'error', Val}, NewEnv}
        
        %% Bind operator
        ({'bind', Left, Right}, Env) ->
            let {LeftVal, Env1} = apply 'do_eval'/2 (Left, Env)
            in
                case LeftVal of
                    {'ok', Value} ->
                        case Right of
                            {'var', FnName} ->
                                apply 'do_eval'/2 ({'call', FnName, [{'int', Value}]}, Env1)
                            <_> ->
                                primop 'error' ({'runtime_error', <<"Right side of >>= must be a function reference">>})
                        end
                    {'error', _} = Error ->
                        {Error, Env1}
                    <_> ->
                        primop 'error' ({'runtime_error', <<"Left side of >>= must be a Result type (Ok or Error)">>})
                end
        
        %% Conditional if/else
        ({'if_expr', Condition, ThenExpr, ElseExpr}, Env) ->
            let {ConditionVal, Env1} = apply 'do_eval'/2 (Condition, Env)
            in
                case ConditionVal of
                    <0> -> apply 'do_eval'/2 (ElseExpr, Env1)
                    <_> -> apply 'do_eval'/2 (ThenExpr, Env1)
                end
        
        ({'if_stmt', Condition, ThenBlock, ElseBlock}, Env) ->
            let {ConditionVal, Env1} = apply 'do_eval'/2 (Condition, Env)
            in
                case ConditionVal of
                    <0> -> apply 'do_eval'/2 (ElseBlock, Env1)
                    <_> -> apply 'do_eval'/2 (ThenBlock, Env1)
                end
        
        %% Yield to block
        ({'yield', _Args}, Env) ->
            case call 'opal_environment':'lookup' (Env, '__block__') of
                {'ok', {'function', _, BlockBody, _BlockEnv}} ->
                    apply 'do_eval'/2 (BlockBody, Env)
                {'error', 'undefined_variable'} ->
                    primop 'error' ({'runtime_error', <<"No block given (yield used outside block context)">>})
            end
        
        %% Function call with block
        ({'call_with_block', Name, Args, Block}, Env) ->
            case call 'opal_environment':'lookup' (Env, Name) of
                {'ok', {'function', Params, Body, ClosureEnv}} ->
                    let EvalArgsFun = fun (Arg, {Values, E}) ->
                            let {Val, E1} = apply 'do_eval'/2 (Arg, E)
                            in {call 'lists':'append' (Values, [Val]), E1}
                        {ArgValues, Env1} = call 'lists':'foldl' (EvalArgsFun, {[], Env}, Args)
                        
                        ExtendedEnv = call 'opal_environment':'extend' (ClosureEnv)
                        ZipFun = fun ({Param, Value}, Acc) ->
                            call 'opal_environment':'define' (Acc, Param, Value)
                        ParamValuePairs = call 'lists':'zip' (Params, ArgValues)
                        CallEnv = call 'lists':'foldl' (ZipFun, ExtendedEnv, ParamValuePairs)
                        
                        BlockFn = {'function', [], Block, Env1}
                        CallEnvWithBlock = call 'opal_environment':'define' (CallEnv, '__block__', BlockFn)
                        
                        OuterEnv = Env1
                        {Result, _UpdatedCallEnv} = apply 'do_eval'/2 (Body, CallEnvWithBlock)
                    in
                        {Result, OuterEnv}
                
                {'ok', _NonFunction} ->
                    let Msg = call 'lists':'concat' ([Name, <<" is not a function">>])
                    in primop 'error' ({'runtime_error', Msg})
                
                {'error', 'undefined_variable'} ->
                    let Msg = call 'lists':'concat' ([<<"Undefined function: ">>, Name])
                    in primop 'error' ({'runtime_error', Msg})
            end
        
        %% Tuple type
        ({'tuple', Elements}, Env) ->
            let EvalElementsFun = fun (Element, {Values, E}) ->
                    let {Val, E1} = apply 'do_eval'/2 (Element, E)
                    in {call 'lists':'append' (Values, [Val]), E1}
                {Values, NewEnv} = call 'lists':'foldl' (EvalElementsFun, {[], Env}, Elements)
                Tuple = call 'erlang':'list_to_tuple' (Values)
            in
                {Tuple, NewEnv}
        
        %% Type definition
        ({'type_def', Name, TypeExpr}, Env) ->
            let {TypeDef, Env1} = apply 'do_eval'/2 (TypeExpr, Env)
                NewEnv = call 'opal_environment':'define' (Env1, Name, {'type', TypeDef})
            in
                {TypeDef, NewEnv}
        
        %% Type expressions
        ({'type_ref', Name}, Env) ->
            case call 'opal_environment':'lookup' (Env, Name) of
                {'ok', {'type', TypeDef}} -> {TypeDef, Env}
                {'ok', _} ->
                    let Msg = call 'lists':'concat' ([Name, <<" is not a type">>])
                    in primop 'error' ({'runtime_error', Msg})
                {'error', 'undefined_variable'} ->
                    let Msg = call 'lists':'concat' ([<<"Undefined type: ">>, Name])
                    in primop 'error' ({'runtime_error', Msg})
            end
        
        ({'ok_type', TypeName}, Env) ->
            {{'ok_type', TypeName}, Env}
        
        ({'error_type', TypeName}, Env) ->
            {{'error_type', TypeName}, Env}
        
        ({'union_type', Left, Right}, Env) ->
            let {LeftType, Env1} = apply 'do_eval'/2 (Left, Env)
                {RightType, Env2} = apply 'do_eval'/2 (Right, Env1)
            in
                {{'union', LeftType, RightType}, Env2}
        
        %% Handle unrecognized AST nodes
        (Unknown, _Env) ->
            let Msg = call 'io_lib':'format' (<<"Unknown expression: ~p">>, [Unknown])
            in primop 'error' ({'runtime_error', Msg})

end