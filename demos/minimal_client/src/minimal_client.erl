-module(minimal_client).

-behaviour(gen_server).


-export([start_link/0, ask/1, ask_async/1]).
-export([init/1, handle_call/3, handle_cast/2]).

-include_lib("dds/include/dds_types.hrl").
-include_lib("ros/include/rmw_dds_msg.hrl").

-record(state,{ ros_node,
                add_client}).

-define(LOCAL_SRV, client).

start_link() -> 
        gen_server:start_link({local, ?LOCAL_SRV},?MODULE, [], []).
ask(Info) ->
        gen_server:call(?LOCAL_SRV,{ask,Info}).
ask_async(Info) ->
        gen_server:cast(?LOCAL_SRV,{ask_async,Info}).
print_result({Msg}) -> 
        io:format("Result: ~p\n",[Msg]).

init(_) -> 
        Node = ros_context:create_node("minimal_client"),

        Client = ros_node:create_client(Node, add_two_ints, fun print_result/1),

        {ok,#state{ros_node=Node, add_client = Client}}.

handle_call({ask,{A,B}}, _, #state{add_client=C} = S) -> 
        case ros_client:service_is_ready(C) of
                true -> {R} = ros_client:call(C, {A,B}), 
                        {reply, R, S};
                false -> {reply, server_unavailable, S}
        end;
handle_call(_,_,S) -> {reply,ok,S}.
handle_cast({ask_async,{A,B}}, #state{add_client=C} = S) -> 
        ros_client:cast(C, {A,B}),
        {noreply,S};
handle_cast(_,S) -> {noreply,S}.


