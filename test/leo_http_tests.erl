%%====================================================================
%%
%% Leo Commons
%%
%% Copyright (c) 2012
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
%% HTTP Util Test
%% @doc
%% @end
%%====================================================================
-module(leo_http_tests).
-author('Yoshiyuki Kanno').

-include("leo_commons.hrl").
-include_lib("eunit/include/eunit.hrl").

%%--------------------------------------------------------------------
%% TEST
%%--------------------------------------------------------------------
-ifdef(EUNIT).
api_test_() ->
    [
     fun key_inc_path_/0,
     fun key_eq_host1_/0,
     fun key_eq_host2_/0,
     fun key_inc_host1_/0,
     fun key_inc_host2_/0,
     fun key_inc_host3_/0,
     fun key_bucket_list_/0,
     fun get_amz_headers_emp_/0,
     fun get_amz_headers_none_/0,
     fun get_amz_headers_normal1_/0,
     fun get_amz_headers_normal2_/0,
     fun get_amz_headers4cow_emp_/0,
     fun get_amz_headers4cow_none_/0,
     fun get_amz_headers4cow_normal1_/0,
     fun get_amz_headers4cow_normal2_/0,
     fun rfc1123_date/0,
     fun web_date/0
    ].


key_inc_path_() ->
    Host = ?S3_DEFAULT_ENDPOINT,
    Path = <<"/bucket/path_to_file.png">>,
    Ret = leo_http:key(Host, Path),

    Expected = binary:part(Path, {1, byte_size(Path) -1}),
    ?assertEqual(Expected, Ret),
    ok.

key_eq_host1_() ->
    Host = <<"www.leofs.com">>,
    Path = <<"/images/path_to_file.png">>,
    Ret = leo_http:key(Host, Path),

    ?assertEqual(<<Host/binary, Path/binary>>, Ret).

key_eq_host2_() ->
    Host = <<"www.leofs.com">>,
    Path = <<"/www.leofs.com/path_to_file.png">>,
    Ret = leo_http:key(Host, Path),

    Expected = binary:part(Path, {1, byte_size(Path) -1}),
    ?assertEqual(Expected, Ret).

key_inc_host1_() ->
    Bucket = <<"bucket">>,
    Host   = <<Bucket/binary, ".", ?S3_DEFAULT_ENDPOINT/binary>>,
    Path = <<"/path_to_file.png">>,
    Ret = leo_http:key(Host, Path),

    ?assertEqual(<<Bucket/binary, Path/binary>>, Ret).

key_inc_host2_() ->
    EndPoint = <<"leofs.org">>,
    Bucket = <<"bucket">>,
    Host = <<Bucket/binary, ".", EndPoint/binary>>,
    Path = <<"/path_to_file.png">>,
    Ret = leo_http:key([EndPoint, <<"localhost">>], Host, Path),

    Expected = <<Bucket/binary, Path/binary>>,
    ?assertEqual(Expected, Ret).

key_inc_host3_() ->
    EndPoints = [<<"leofs.org">>, <<"test.leofs.org">>],
    Bucket = <<"bucket">>,
    Host = <<Bucket/binary, ".test.leofs.org" >>,
    Path = <<"/path_to_file.png">>,
    Ret = leo_http:key(EndPoints, Host, Path),

    Expected = <<Bucket/binary, Path/binary>>,
    ?assertEqual(Expected, Ret).


key_bucket_list_() ->
    Host = ?S3_DEFAULT_ENDPOINT,
    Path = <<"/">>,
    Ret = leo_http:key(Host, Path),
    ?assertEqual(Path, Ret),

    Path2 = <<"">>,
    Ret2 = leo_http:key(Host, Path2),
    ?assertEqual(Path, Ret2).


get_amz_headers_emp_() ->
    T1 = gb_trees:empty(),
    ?assertEqual([], leo_http:get_amz_headers(T1)).

get_amz_headers_none_() ->
    T1 = gb_trees:empty(),
    T2 = gb_trees:enter("Date", {"Date", "Tue, 27 Mar 2007 21:15:45 +0000"}, T1),
    T3 = gb_trees:enter("Host", {"Host", "johnsmith.s3.amazonaws.com"}, T2),
    T4 = gb_trees:enter("Content-Length", {"Content-Length", 94328}, T3),
    T5 = gb_trees:enter("Content-Type", {"Content-Type", "image/jpeg"}, T4),
    ?assertEqual([], leo_http:get_amz_headers(T5)).

get_amz_headers_normal1_() ->
    T1 = gb_trees:empty(),
    T2 = gb_trees:enter("Date", {"Date", "Tue, 27 Mar 2007 21:15:45 +0000"}, T1),
    Key = "x-amz-date",
    Val = "Tue, 27 Mar 2007 21:20:26 +0000",
    T3 = gb_trees:enter(Key, {Key, Val}, T2),
    AmzHeaders = leo_http:get_amz_headers(T3),
    ?assertEqual(1, length(AmzHeaders)),
    ?assertEqual({Key, Val}, hd(AmzHeaders)).

get_amz_headers_normal2_() ->
    T1 = gb_trees:empty(),
    Key = "x-amz-date",
    Val = "Tue, 27 Mar 2007 21:20:26 +0000",
    T2 = gb_trees:enter(Key, {Key, Val}, T1),
    Key2 = "X-Amz-Meta-ReviewedBy",
    Val2 = "jane@johnsmith.net",
    T3 = gb_trees:enter(Key2, {Key2, Val2}, T2),
    AmzHeaders = leo_http:get_amz_headers(T3),
    ?assertEqual(2, length(AmzHeaders)).

rfc1123_date() ->
    ?assertNotEqual([], leo_http:rfc1123_date(leo_date:now())).

web_date() ->
    ?assertEqual("2012-07-04T12:34:56.000Z", leo_http:web_date(63508624496)).

get_amz_headers4cow_emp_() ->
    ?assertEqual([], leo_http:get_amz_headers4cow([])).

get_amz_headers4cow_none_() ->
    List = [{"Date", "Tue, 27 Mar 2007 21:15:45 +0000"},
            {'Host', "johnsmith.s3.amazonaws.com"},
            {<<"Content-Length">>, 94328},
            {<<"Content-Type">>, "image/jpeg"}],
    ?assertEqual([], leo_http:get_amz_headers4cow(List)).

get_amz_headers4cow_normal1_() ->
    Key = <<"X-Amz-Date">>,
    Val = <<"Tue, 27 Mar 2007 21:15:45 +0000">>,
    List = [{"Date", "Tue, 27 Mar 2007 21:15:45 +0000"},
            {'Host', "johnsmith.s3.amazonaws.com"},
            {Key, Val}],
    AmzHeaders = leo_http:get_amz_headers4cow(List),
    ?assertEqual(1, length(AmzHeaders)),
    ?assertEqual({binary_to_list(Key), binary_to_list(Val)}, hd(AmzHeaders)).

get_amz_headers4cow_normal2_() ->
    Key = <<"X-Amz-Date">>,
    Val = <<"Tue, 27 Mar 2007 21:15:45 +0000">>,
    Key2 = <<"X-Amz-Meta-ReviewedBy">>,
    Val2 = <<"jane@johnsmith.net">>,
    List = [{Key2, Val2},
            {'Host', "johnsmith.s3.amazonaws.com"},
            {Key, Val}],
    AmzHeaders = leo_http:get_amz_headers4cow(List),
    ?assertEqual(2, length(AmzHeaders)).

-endif.
