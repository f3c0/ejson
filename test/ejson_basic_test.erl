-module(ejson_basic_test).

-import(ejson_test_util, [json_prop/2]).

-include_lib("eunit/include/eunit.hrl").

value_test_() ->
    Cases = [1, 3.4, true, false],
    [?_assertEqual({ok, Expected}, ejson_encode:encode(Expected, []))
        || Expected <- Cases].

null_test_() ->
    ?_assertEqual({ok, null}, ejson_encode:encode(undefined, [])).

list_test_() ->
    Cases = [
             [],
             [1, 2],
             [true, 9],
             [6.55, false],
             [1, [], [2, 3]]
            ],
    [?_assertEqual({ok, Expected}, ejson_encode:encode(Expected, []))
        || Expected <- Cases].

enc_fun(Num) -> Num * 1000.
dec_fun(Num) -> Num div 1000.

field_fun_test_() ->
    Opts = [{time, {field_fun, "jsTime", {?MODULE, enc_fun},
                                         {?MODULE, dec_fun}}}],
    Record = {time, 2300},
    {ok, E} = ejson_encode:encode(Record, Opts),
    ?debugVal(E),
    {ok, D} = ejson_decode:decode(E, Opts),
    ?_assert(Record =:= D).

-define(TYPE(Val, Opts, Err),
        ?_assertEqual(Exp(Val, Err), Enc(Val, Opts))).

type_fail_test_() ->
    Opts1 = [{request, {atom, "method"}}],
    Opts2 = [{request, {binary, "method"}}],
    Opts3 = [{request, {list, "method"}}],

    Enc = fun(V, O) -> ejson_encode:encode({request, V}, O) end,
    Exp = fun(V, E) -> {error, {E, "method", V}} end,

    %% Test when atom is expected but other data are passed
    [?TYPE("string", Opts1, atom_value_expected),
     ?TYPE(1, Opts1, atom_value_expected),
     ?TYPE(<<"apple">>, Opts1, atom_value_expected),
     ?TYPE("test", Opts2, binary_value_expected),
     ?TYPE(3, Opts2, binary_value_expected),
     ?TYPE(1, Opts3, list_value_expected)].

embedded_record_test_() ->
    Opts = [{person, {string, name}, {record, address}},
            {address, {string, city}, {string, country}}],
    Rec = {person, "Joe", {address, "Budapest", "Hun"}},
    {ok, Enc} = ejson_encode:encode(Rec, Opts),
    {ok, Dec} = ejson_decode:decode(Enc, Opts),
    ?debugVal(Dec),
    Addr = json_prop(Enc, "address"),
    [?_assertEqual(<<"Joe">>, json_prop(Enc, "name")),
     ?_assertEqual(<<"Budapest">>, json_prop(Addr, "city")),
     ?_assertEqual(<<"Hun">>, json_prop(Addr, "country")),
     ?_assertMatch({person, _, {address, "Budapest", "Hun"}}, Dec)].
