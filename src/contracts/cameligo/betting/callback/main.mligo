#import "../types.mligo" "BETTING_Types"

type storage =
  [@layout:comb] {
  name : string;
  videogame : string;
  begin_at : timestamp;
  end_at : timestamp;
  modified_at : timestamp;
  opponents : { team_one : string; team_two : string};
  game_status : BETTING_Types.game_status;
  start_bet_time : timestamp;
  closed_bet_time : timestamp;
  bets_team_one : (address, tez) map;
  bets_team_one_index : nat;
  bets_team_one_total : tez;
  bets_team_two : (address, tez) map;
  bets_team_two_index : nat;
  bets_team_two_total : tez;
  meta : (string, bytes) map;
  bettingAddr : address;
  }

type requested_event_param = [@layout:comb] {
  name : string;
  videogame : string;
  begin_at : timestamp;
  end_at : timestamp;
  modified_at : timestamp;
  opponents : { team_one : string; team_two : string};
  game_status : BETTING_Types.game_status;
  start_bet_time : timestamp;
  closed_bet_time : timestamp;
  bets_team_one : (address, tez) map;
  bets_team_one_index : nat;
  bets_team_one_total : tez;
  bets_team_two : (address, tez) map;
  bets_team_two_index : nat;
  bets_team_two_total : tez;
}

[@entry] let saveEvent(param : requested_event_param) (store : storage) : operation list * storage =
  (([]: operation list), { store with
    name=param.name;
    videogame=param.videogame;
    begin_at=param.begin_at;
    end_at=param.end_at;
    modified_at=param.modified_at;
    opponents=param.opponents;
    game_status=param.game_status;
    start_bet_time=param.start_bet_time;
    closed_bet_time=param.closed_bet_time;
    bets_team_one=param.bets_team_one;
    bets_team_one_index=param.bets_team_one_index;
    bets_team_one_total=param.bets_team_one_total;
    bets_team_two=param.bets_team_two;
    bets_team_two_index=param.bets_team_two_index;
    bets_team_two_total=param.bets_team_two_total;
  })

[@entry] let requestEvent(param : nat) (store : storage) : operation list * storage =
  let payload : BETTING_Types.callback_asked_parameter = {
    requested_event_id=param;
    callback=Tezos.get_self_address();
  } in
  let destination : BETTING_Types.callback_asked_parameter contract =
    match (Tezos.get_entrypoint_opt "%getEvent" store.bettingAddr : BETTING_Types.callback_asked_parameter contract option) with
    | None -> failwith("Unknown entrypoint GetEvent")
    | Some ctr -> ctr
  in
  let op : operation = Tezos.transaction payload 0mutez destination in
  ([op], store)