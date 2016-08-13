%
% Copyright (c) 2016 Petr Gotthard <petr.gotthard@centrum.cz>
% All rights reserved.
% Distributed under the terms of the MIT License. See the LICENSE file.
%
-module(lorawan_admin_devices).

-export([init/2]).
-export([is_authorized/2]).
-export([allowed_methods/2]).
-export([content_types_provided/2]).
-export([content_types_accepted/2]).

-export([get_devices/2]).
-export([create_device/2]).

-include("lorawan.hrl").

init(Req, Opts) ->
    {cowboy_rest, Req, Opts}.

is_authorized(Req, State) ->
    lorawan_admin:handle_authorization(Req, State).

allowed_methods(Req, State) ->
    {[<<"OPTIONS">>, <<"GET">>, <<"POST">>], Req, State}.

content_types_provided(Req, State) ->
    {[
        {{<<"application">>, <<"json">>, []}, get_devices}
    ], Req, State}.

get_devices(Req, User) ->
    {jsx:encode(read_devices()), Req, User}.

read_devices() ->
    lists:foldl(
        fun(Key, Acc)->
            [Rec] = mnesia:dirty_read(devices, Key),
            [lorawan_admin:build_device(Rec)|Acc]
        end,
        [],
        mnesia:dirty_all_keys(devices)).

content_types_accepted(Req, State) ->
    {[
        {{<<"application">>, <<"json">>, '*'}, create_device}
    ], Req, State}.

create_device(Req, State) ->
    {ok, Data, Req2} = cowboy_req:read_body(Req),
    case jsx:is_json(Data) of
        true ->
            Rec = lorawan_admin:parse_device(jsx:decode(Data, [{labels, atom}])),
            mnesia:transaction(fun() ->
                ok = mnesia:write(devices, Rec, write) end),
            {true, Req2, State};
        false ->
            {stop, cowboy_req:reply(400, Req2), State}
    end.

% end of file
