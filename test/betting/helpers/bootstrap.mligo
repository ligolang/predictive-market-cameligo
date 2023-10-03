#import "../../../src/contracts/cameligo/betting/callback/main.mligo" "Callback"
#import "../../../src/contracts/cameligo/betting/main.mligo" "Betting"
#import "../../../src/contracts/cameligo/betting/types.mligo" "Types"
#import "callback.mligo" "Helper_betting_callback"

let plain_timestamp : timestamp = ("1970-01-01T00:00:01Z" : timestamp)

let bootstrap () =
  (* Boostrapping accounts *)
  let () = Test.reset_state 6n ([] : tez list) in
  let _baker: address = Test.nth_bootstrap_account 0 in
  let elon:   address = Test.nth_bootstrap_account 1 in
  let jeff:   address = Test.nth_bootstrap_account 2 in
  let alice:  address = Test.nth_bootstrap_account 3 in
  let bob:    address = Test.nth_bootstrap_account 4 in
  let james:  address = Test.nth_bootstrap_account 5 in

  let init_bet_config : Types.bet_config_type = {
    is_betting_paused       = false;
    is_event_creation_paused = false;
    min_bet_amount          = 1tez;
    retained_profit_quota   = 10n;
  } in

  (* Boostrapping storage *)
  let init_storage : Types.storage = {
    manager        = elon;
    oracle_address = jeff;
    bet_config     = init_bet_config;
    events         = (Big_map.empty : (nat, Types.event_type) big_map);
    events_bets    = (Big_map.empty : (nat, Types.event_bets) big_map);
    events_index   = 0n;
    meta           = (Map.empty : (string, bytes) map);
  } in

  (* Boostrapping BETTING contract *)
  let betting_path = "../../../src/contracts/cameligo/betting/main.mligo" in
  let orig = Test.originate_from_file betting_path init_storage 0mutez in
  let betting_contract = Test.to_contract orig.addr in
  let betting_address = Test.to_address orig.addr in

  (betting_address, betting_contract, orig.addr, elon, jeff, alice, bob, james)

let bootstrap_betting_callback (bettingAddr : address) =
    let betting_callback = Helper_betting_callback.originate_from_file(Helper_betting_callback.base_storage(bettingAddr)) in
    betting_callback

