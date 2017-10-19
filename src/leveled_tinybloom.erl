%% -------- TinyBloom ---------
%%
%% A fixed size bloom that supports 128 keys only, made to try and minimise
%% the cost of producing the bloom
%%


-module(leveled_tinybloom).

-include("include/leveled.hrl").

-include_lib("eunit/include/eunit.hrl").

-export([
            create_bloom/1,
            check_hash/2
            ]).


%%%============================================================================
%%% API
%%%============================================================================

-spec create_bloom(list(integer())) -> binary().
%% @doc
%% Create a binary bloom filter from a list of hashes
create_bloom(HashList) ->
    case length(HashList) of
        0 ->
            <<>>;
        L when L > 32 ->
            add_hashlist(HashList,
                            15,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0);
        L when L > 16 ->
            add_hashlist(HashList, 3, 0, 0, 0, 0);
        _ ->
            add_hashlist(HashList, 1, 0, 0)
    end.

-spec check_hash(integer(), binary()) -> boolean().
%% @doc
%% Check for the presence of a given hash within a bloom
check_hash(_Hash, <<>>) ->
    false;
check_hash(Hash, BloomBin) ->
    SlotSplit = (byte_size(BloomBin) div 8) - 1,
    {Slot, H0, H1, H2, Switch} = split_hash(Hash, SlotSplit),
    Mask = get_mask(H0, H1, H2, Switch),
    Pos = Slot * 8,
    <<_H:Pos/binary, CheckInt:64/integer, _T/binary>> = BloomBin,
    case CheckInt band Mask of
        Mask ->
            true;
        _ ->
            false
    end.
    
%%%============================================================================
%%% Internal Functions
%%%============================================================================

split_hash(Hash, SlotSplit) ->
    S0 = Hash band 31,
    H0 = (Hash bsr 5) band 31,
    H1 = (Hash bsr 10) band 31,
    H2 = (Hash bsr 15) band 31,
    {S0 band SlotSplit, H0, H1, H2, S0 bsr 4}.

get_mask(H0, H1, H2, Switch) ->
    case Switch of 
        0 ->
            ((1 bsl H0) bor (1 bsl H1) bor (1 bsl H2)) bsl 32;
        1 ->
            (1 bsl H0) bor (1 bsl H1) bor (1 bsl H2)
    end.


%% This looks ugly and clunky, but in tests it was quicker than modifying an
%% Erlang term like an array as it is passed around the loop

add_hashlist([], _S, S0, S1) ->
    <<S0:64/integer, S1:64/integer>>;
add_hashlist([TopHash|T], SlotSplit, S0, S1) ->
    {Slot, H0, H1, H2, Switch} = split_hash(TopHash, SlotSplit),
    Mask = get_mask(H0, H1, H2, Switch),
    case Slot of
        0 ->
            add_hashlist(T, SlotSplit, S0 bor Mask, S1);
        1 ->
            add_hashlist(T, SlotSplit, S0, S1 bor Mask)
    end.

add_hashlist([], _S, S0, S1, S2, S3) ->
     <<S0:64/integer, S1:64/integer, S2:64/integer, S3:64/integer>>;
add_hashlist([TopHash|T], SlotSplit, S0, S1, S2, S3) ->
    {Slot, H0, H1, H2, Switch} = split_hash(TopHash, SlotSplit),
    Mask = get_mask(H0, H1, H2, Switch),
    case Slot of
        0 ->
            add_hashlist(T, SlotSplit, S0 bor Mask, S1, S2, S3);
        1 ->
            add_hashlist(T, SlotSplit, S0, S1 bor Mask, S2, S3);
        2 ->
            add_hashlist(T, SlotSplit, S0, S1, S2 bor Mask, S3);
        3 ->
            add_hashlist(T, SlotSplit, S0, S1, S2, S3 bor Mask)
    end.

add_hashlist([], _S, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                                                    SA, SB, SC, SD, SE, SF) ->
    
    <<S0:64/integer, S1:64/integer, S2:64/integer, S3:64/integer,
        S4:64/integer, S5:64/integer, S6:64/integer, S7:64/integer,
        S8:64/integer, S9:64/integer, SA:64/integer, SB:64/integer,
        SC:64/integer, SD:64/integer, SE:64/integer, SF:64/integer>>;
add_hashlist([TopHash|T],
                SlotSplit,
                S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                SA, SB, SC, SD, SE, SF) ->
    {Slot, H0, H1, H2, Switch} = split_hash(TopHash, SlotSplit),
    Mask = get_mask(H0, H1, H2, Switch),
    case Slot of
        0 ->
            add_hashlist(T,
                            SlotSplit,
                            S0 bor Mask, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        1 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1 bor Mask, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        2 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2 bor Mask, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        3 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3 bor Mask, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        4 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4 bor Mask, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        5 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5 bor Mask, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        6 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6 bor Mask, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        7 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7 bor Mask, S8, S9,
                            SA, SB, SC, SD, SE, SF);
        8 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8 bor Mask, S9,
                            SA, SB, SC, SD, SE, SF);
        9 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8, S9 bor Mask,
                            SA, SB, SC, SD, SE, SF);
        10 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA bor Mask, SB, SC, SD, SE, SF);
        11 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB bor Mask, SC, SD, SE, SF);
        12 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC bor Mask, SD, SE, SF);
        13 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD bor Mask, SE, SF);
        14 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE bor Mask, SF);
        15 ->
            add_hashlist(T,
                            SlotSplit,
                            S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
                            SA, SB, SC, SD, SE, SF bor Mask)
    end.


%%%============================================================================
%%% Test
%%%============================================================================

-ifdef(TEST).

generate_randomkeys(Seqn, Count, BucketRangeLow, BucketRangeHigh) ->
    generate_randomkeys(Seqn,
                        Count,
                        [],
                        BucketRangeLow,
                        BucketRangeHigh).

generate_randomkeys(_Seqn, 0, Acc, _BucketLow, _BucketHigh) ->
    Acc;
generate_randomkeys(Seqn, Count, Acc, BucketLow, BRange) ->
    BRand = leveled_rand:uniform(BRange),
    BNumber = string:right(integer_to_list(BucketLow + BRand), 4, $0),
    KNumber = string:right(integer_to_list(leveled_rand:uniform(10000)), 6, $0),
    LK = leveled_codec:to_ledgerkey("Bucket" ++ BNumber, "Key" ++ KNumber, o),
    Chunk = leveled_rand:rand_bytes(64),
    {_B, _K, MV, _H, _LMs} =
        leveled_codec:generate_ledgerkv(LK, Seqn, Chunk, 64, infinity),
    generate_randomkeys(Seqn + 1,
                        Count - 1,
                        [{LK, MV}|Acc],
                        BucketLow,
                        BRange).


get_hashlist(N) ->
    KVL0 = lists:ukeysort(1, generate_randomkeys(1, N * 2, 1, 20)),
    KVL = lists:sublist(KVL0, N),
    HashFun =
        fun({K, _V}) ->
            leveled_codec:segment_id(K)
        end,
    lists:map(HashFun, KVL).

check_all_hashes(BloomBin, HashList) ->
    CheckFun =
        fun(Hash) ->
            ?assertMatch(true, check_hash(Hash, BloomBin))
        end,
    lists:foreach(CheckFun, HashList).
        
check_neg_hashes(BloomBin, HashList, Counters) ->
    CheckFun =
        fun(Hash, {AccT, AccF}) ->
            case check_hash(Hash, BloomBin) of
                true ->
                    {AccT + 1, AccF};
                false ->
                    {AccT, AccF + 1}
            end
        end,
    lists:foldl(CheckFun, Counters, HashList).


empty_bloom_test() ->
    BloomBin0 = create_bloom([]),
    ?assertMatch({0, 4},
                    check_neg_hashes(BloomBin0, [0, 10, 100, 100000], {0, 0})).

bloom_test() ->
    test_bloom(128, 2000),
    test_bloom(64, 10),
    test_bloom(32, 10),
    test_bloom(16, 10),
    test_bloom(8, 10).

test_bloom(N, Runs) ->
    ListOfHashLists = 
        lists:map(fun(_X) -> get_hashlist(N) end, lists:seq(1, Runs)),
    
    SWa = os:timestamp(),
    ListOfBlooms =
        lists:map(fun(HL) -> create_bloom(HL) end, ListOfHashLists),
    TSa = timer:now_diff(os:timestamp(), SWa),
    
    SWb = os:timestamp(),
    lists:foreach(fun(Nth) ->
                        HL = lists:nth(Nth, ListOfHashLists),
                        BB = lists:nth(Nth, ListOfBlooms),
                        check_all_hashes(BB, HL)
                     end,
                     lists:seq(1, Runs)),
    TSb = timer:now_diff(os:timestamp(), SWb),
     
    HashPool = get_hashlist(N * 2),
    ListOfMisses = 
        lists:map(fun(HL) ->
                        lists:sublist(lists:subtract(HashPool, HL), N)
                    end,
                    ListOfHashLists),

    SWc = os:timestamp(),
    {Pos, Neg} = 
        lists:foldl(fun(Nth, Acc) ->
                            HL = lists:nth(Nth, ListOfMisses),
                            BB = lists:nth(Nth, ListOfBlooms),
                            check_neg_hashes(BB, HL, Acc)
                        end,
                        {0, 0},
                        lists:seq(1, Runs)),
    FPR = Pos / (Pos + Neg),
    TSc = timer:now_diff(os:timestamp(), SWc),
    
    io:format(user,
                "Test with size ~w has microsecond timings: -"
                    ++ " build ~w check ~w neg_check ~w and fpr ~w~n",
                [N, TSa, TSb, TSc, FPR]).



-endif.
