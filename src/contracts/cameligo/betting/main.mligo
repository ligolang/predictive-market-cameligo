// Betting & Predictive Market - CameLIGO contract

#import "types.mligo" "Types"
#import "errors.mligo" "Errors"
#import "assert.mligo" "Assert"
#import "callback/main.mligo" "Betting_Callback"


// --------------------------------------
//      CONFIGURATION INTERACTIONS
// --------------------------------------

[@entry] let changeManager (p_new_manager : address)(s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  let _ = Assert.not_previous_manager p_new_manager s.manager in
  (([] : operation list), {s with manager = p_new_manager})

[@entry] let changeOracleAddress (p_new_oracle_address : address)(s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  let _ = Assert.not_previous_oracle p_new_oracle_address s.oracle_address in
  (([] : operation list), {s with oracle_address = p_new_oracle_address})

[@entry] let switchPauseEventCreation (() : unit) (s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  (([] : operation list), {s with bet_config.is_event_creation_paused = (not s.bet_config.is_event_creation_paused)})

[@entry] let switchPauseBetting (() : unit) (s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  (([] : operation list), {s with bet_config.is_betting_paused = (not s.bet_config.is_betting_paused)})

[@entry] let updateConfigType (p_new_bet_config : Types.bet_config_type)(s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  (([] : operation list), {s with bet_config = p_new_bet_config})

// --------------------------------------
//          EVENT INTERACTIONS
// --------------------------------------

[@entry] let addEvent (p_new_event : Types.add_event_parameter)(s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager_or_oracle (Tezos.get_sender()) s.manager s.oracle_address in
  let _ = Assert.event_creation_not_paused s.bet_config.is_event_creation_paused in
  let _ = Assert.event_start_to_end_date p_new_event.begin_at p_new_event.end_at in
  let _ = Assert.event_bet_start_to_end_date p_new_event.start_bet_time p_new_event.closed_bet_time in
  let _ = Assert.event_bet_start_after_end p_new_event.start_bet_time p_new_event.end_at in
  let _ = Assert.event_bet_ends_after_end p_new_event.closed_bet_time p_new_event.end_at in
  let new_event : Types.event_type = {
    name = p_new_event.name;
    videogame =  p_new_event.videogame;
    begin_at = p_new_event.begin_at;
    end_at = p_new_event.end_at;
    modified_at = p_new_event.modified_at;
    opponents = p_new_event.opponents;
    game_status = Ongoing;
    start_bet_time = p_new_event.start_bet_time;
    closed_bet_time = p_new_event.closed_bet_time;
    is_claimed = False } in
  let new_events : (nat, Types.event_type) big_map = (Big_map.add (s.events_index) new_event s.events) in
  let new_event_bet : Types.event_bets = {
    bets_team_one = (Map.empty : (address, tez) map);
    bets_team_one_index = 0n;
    bets_team_one_total = 0mutez;
    bets_team_two = (Map.empty : (address, tez) map);
    bets_team_two_index = 0n;
    bets_team_two_total = 0mutez;
  } in
  let new_events_bets : (nat, Types.event_bets) big_map = (Big_map.add (s.events_index) new_event_bet s.events_bets) in
  (([] : operation list), {s with events = new_events; events_bets = new_events_bets; events_index = (s.events_index + 1n)})


[@entry] let getEvent (callback_asked_param : Types.callback_asked_parameter)(s : Types.storage) : (operation list * Types.storage) =
  let { requested_event_id ; callback } = callback_asked_param in
  let cbk_event = match Big_map.find_opt requested_event_id s.events with
    | Some event -> event
    | None -> (failwith Errors.no_event_id)
    in
  let cbk_eventbet = match Big_map.find_opt requested_event_id s.events_bets with
    | Some eventbet -> eventbet
    | None -> (failwith Errors.no_event_id)
    in
  let payload : Betting_Callback.requested_event_param = {
    name = cbk_event.name;
    videogame = cbk_event.videogame;
    begin_at = cbk_event.begin_at;
    end_at = cbk_event.end_at;
    modified_at = cbk_event.modified_at;
    opponents = { team_one = cbk_event.opponents.team_one; team_two = cbk_event.opponents.team_two};
    game_status = cbk_event.game_status;
    start_bet_time = cbk_event.start_bet_time;
    closed_bet_time = cbk_event.closed_bet_time;
    bets_team_one = cbk_eventbet.bets_team_one;
    bets_team_one_index = cbk_eventbet.bets_team_one_index;
    bets_team_one_total = cbk_eventbet.bets_team_one_total;
    bets_team_two = cbk_eventbet.bets_team_two;
    bets_team_two_index = cbk_eventbet.bets_team_two_index;
    bets_team_two_total = cbk_eventbet.bets_team_two_total;
  } in
  let destination : Betting_Callback.requested_event_param contract =
    match (Tezos.get_entrypoint_opt "%saveEvent" callback : Betting_Callback.requested_event_param contract option) with
    | None -> failwith("Unknown contract")
    | Some ctr -> ctr
  in
  let op : operation = Tezos.transaction payload 0mutez destination in
  ([op], s)


[@entry] let updateEvent (update_event_param : Types.update_event_parameter)(s : Types.storage) : (operation list * Types.storage) =
  let { updated_event_id; updated_event } = update_event_param in
  let _ = Assert.is_manager_or_oracle (Tezos.get_sender()) s.manager s.oracle_address in
  let _ = Assert.event_start_to_end_date updated_event.begin_at updated_event.end_at in
  let _ = Assert.event_bet_start_to_end_date updated_event.start_bet_time updated_event.closed_bet_time in
  let _ = Assert.event_bet_start_after_end updated_event.start_bet_time updated_event.end_at in
  let _ = Assert.event_bet_ends_after_end updated_event.closed_bet_time updated_event.end_at in
  let requested_event = match Big_map.find_opt updated_event_id s.events with
    | Some event -> event
    | None -> (failwith Errors.no_event_id)
  in
  let _ = Assert.betting_not_finalized (requested_event.game_status) in
  let new_events : (nat, Types.event_type) big_map = Big_map.update updated_event_id (Some(updated_event)) s.events in
  (([] : operation list), {s with events = new_events})

// --------------------------------------
//         BETTING INTERACTIONS
// --------------------------------------

let add_bet_team_one_amount_to_existing_user (p_requested_event_id : Types.event_bets)(pPreviousAmount : tez) =
  let p_new_bets_team_one : (address, tez) map = Map.update (Tezos.get_sender()) (Some(pPreviousAmount + Tezos.get_amount())) p_requested_event_id.bets_team_one in
  (p_new_bets_team_one, p_requested_event_id.bets_team_one_index)


let add_bet_team_one_amount_to_new_user (p_requested_event_id : Types.event_bets) =
  let p_new_bets_team_one : (address, tez) map = Map.add (Tezos.get_sender()) (Tezos.get_amount()) p_requested_event_id.bets_team_one in
  let p_new_bets_team_one_index : nat = (p_requested_event_id.bets_team_one_index + 1n) in
  (p_new_bets_team_one, p_new_bets_team_one_index)


let add_bet_team_one (p_requested_event_id : Types.event_bets) : Types.event_bets =
  let (new_bets_team_one, new_bets_team_one_index) : ((address, tez) map * nat) = match (Map.find_opt (Tezos.get_sender()) p_requested_event_id.bets_team_one) with
    | Some prevAmount -> add_bet_team_one_amount_to_existing_user p_requested_event_id prevAmount
    | None -> add_bet_team_one_amount_to_new_user p_requested_event_id
  in
  let new_bets_team_one_total : tez = (p_requested_event_id.bets_team_one_total + Tezos.get_amount()) in
  let r_updated_event : Types.event_bets = {p_requested_event_id with bets_team_one = new_bets_team_one; bets_team_one_index = new_bets_team_one_index; bets_team_one_total = new_bets_team_one_total;} in
  (r_updated_event)


let add_bet_team_two_amount_to_existing_user (p_requested_event_id : Types.event_bets)(pPreviousAmount : tez) =
  let p_newbets_team_two : (address, tez) map = Map.update (Tezos.get_sender()) (Some(pPreviousAmount + Tezos.get_amount())) p_requested_event_id.bets_team_two in
  (p_newbets_team_two, p_requested_event_id.bets_team_two_index)


let add_bet_team_twoAmountToNewUser (p_requested_event_id : Types.event_bets) =
  let p_newbets_team_two : (address, tez) map = Map.add (Tezos.get_sender()) (Tezos.get_amount()) p_requested_event_id.bets_team_two in
  let p_newbets_team_two_index : nat = (p_requested_event_id.bets_team_two_index + 1n) in
  (p_newbets_team_two, p_newbets_team_two_index)


let add_bet_team_two (p_requested_event_id : Types.event_bets) : Types.event_bets =
  let (newbets_team_two, newbets_team_two_index) : ((address, tez) map * nat) = match (Map.find_opt (Tezos.get_sender()) p_requested_event_id.bets_team_two) with
    | Some prevAmount -> add_bet_team_two_amount_to_existing_user p_requested_event_id prevAmount
    | None -> add_bet_team_twoAmountToNewUser p_requested_event_id
  in
  let newbets_team_two_total : tez = (p_requested_event_id.bets_team_two_total + Tezos.get_amount()) in
  let r_updated_event : Types.event_bets = {p_requested_event_id with bets_team_two = newbets_team_two; bets_team_two_index = newbets_team_two_index; bets_team_two_total = newbets_team_two_total;} in
  (r_updated_event)


[@entry] let addBet (add_bet_param : Types.add_bet_parameter) (s : Types.storage) : (operation list * Types.storage) =
  let { requested_event_id; team_one_bet } = add_bet_param in
  let _ = Assert.not_manager_nor_oracle (Tezos.get_sender()) s.manager s.oracle_address in
  let _ = Assert.no_tez (Tezos.get_amount()) in
  let _ = Assert.tez_lower_than_min (Tezos.get_amount()) s.bet_config.min_bet_amount in
  let requested_event : Types.event_type = match (Big_map.find_opt requested_event_id s.events) with
    | Some event -> event
    | None -> failwith Errors.no_event_id
  in
  let _ = Assert.betting_not_finalized (requested_event.game_status) in
  let _ = Assert.betting_before_period_start (requested_event.start_bet_time) in
  let _ = Assert.betting_after_period_end (requested_event.closed_bet_time) in
  let requested_event_bets : Types.event_bets = match (Big_map.find_opt requested_event_id s.events_bets) with
    | Some event -> event
    | None -> failwith Errors.no_event_bets
  in
  let updated_bet_event : Types.event_bets = if (team_one_bet)
    then add_bet_team_one requested_event_bets
    else add_bet_team_two requested_event_bets
  in
  let new_events_map : (nat, Types.event_bets) big_map = (Big_map.update requested_event_id (Some(updated_bet_event)) s.events_bets) in
  (([] : operation list), {s with events_bets = new_events_map;})

let make_transfer_op (addr : address ) ( value_won : tez ) (profit_quota : nat): operation =
  let quota_to_send : nat = abs(100n - profit_quota) in
  let value_to_send : tez = value_won * quota_to_send / 100n in
  let dest_opt : unit contract option = Tezos.get_contract_opt addr in
  let destination : unit contract = match dest_opt with
    | None    -> failwith "Not found"
    | Some ct -> ct
  in
  Tezos.transaction unit value_to_send destination

let compose_payment ( winner_map : (address, tez) map ) ( total_value_bet : tez ) ( total_value_won : tez ) (profit_quota : nat) : operation list =
  let folded_op_list = fun (op_list, (address, bet_amount) : operation list * (address * tez) ) ->
    let won_reward_percentage : nat = 10000000n * bet_amount / total_value_bet in
    let added_reward : tez =  total_value_won * won_reward_percentage / 10000000n in
    let reward_to_distribute : tez = bet_amount + added_reward in
    let reward_op : operation = make_transfer_op address reward_to_distribute profit_quota in
    reward_op :: op_list
  in
  let empty_op_list : operation list = [] in
  Map.fold folded_op_list winner_map empty_op_list

let refund_bet (event_bets : Types.event_bets) (profit_quota : nat) : operation list =
  let folded_op_list = fun (op_list, (address, bet_amount) : operation list * (address * tez) ) ->
    let refund_op : operation = make_transfer_op address bet_amount profit_quota in
    refund_op :: op_list
  in
  let empty_op_list : operation list = [] in
  let team_one_refund : operation list = Map.fold folded_op_list event_bets.bets_team_one empty_op_list   in
  let total_refund    : operation list = Map.fold folded_op_list event_bets.bets_team_two team_one_refund in
  total_refund

let resolve_team_win (event_bets : Types.event_bets) (is_team_one_win : bool) (profit_quota : nat) : operation list =
  if (event_bets.bets_team_one_total = 0mutez or event_bets.bets_team_two_total = 0mutez)
  then refund_bet event_bets 0n
  else if (is_team_one_win)
    then
      compose_payment event_bets.bets_team_one event_bets.bets_team_one_total event_bets.bets_team_two_total profit_quota
    else
      compose_payment event_bets.bets_team_two event_bets.bets_team_two_total event_bets.bets_team_one_total profit_quota

[@entry] let finalizeBet (p_requested_event_id : nat) (s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  let requested_event : Types.event_type = match (Big_map.find_opt p_requested_event_id s.events) with
    | Some event -> event
    | None -> failwith Errors.no_event_id
  in
  let _check_is_claimed : unit = assert_with_error (requested_event.is_claimed = False) Errors.event_already_claimed in
  let _ = Assert.betting_finalized (requested_event.game_status) in
  let event_bets : Types.event_bets = match (Big_map.find_opt p_requested_event_id s.events_bets) with
    | Some event -> event
    | None -> failwith Errors.no_event_bets
  in
  let _ = Assert.finalizing_before_period_end (requested_event.end_at) in
  let profit_quota : nat = s.bet_config.retained_profit_quota in
  let modified_events = Big_map.update p_requested_event_id (Some({ requested_event with is_claimed = True })) s.events in
  let op_list : operation list = match requested_event.game_status with
    | Ongoing  -> failwith Errors.bet_no_team_outcome
    | Team1Win -> resolve_team_win event_bets true  profit_quota
    | Team2Win -> resolve_team_win event_bets false profit_quota
    | Draw     -> refund_bet event_bets profit_quota
  in
  ((op_list : operation list), { s with events = modified_events })


// --------------------------------------
//            CONTRACT VIEWS
// --------------------------------------

[@view]
let getManager (_ : unit) (s : Types.storage) : timestamp * address =
  (Tezos.get_now(), s.manager)

[@view]
let getOracleAddress (_ : unit) (s : Types.storage) : timestamp * address =
  (Tezos.get_now(), s.oracle_address)

[@view]
let getBettingStatus (_ : unit) (s : Types.storage) : timestamp * bool =
  (Tezos.get_now(), s.bet_config.is_betting_paused)

[@view]
let getEventCreationStatus (_ : unit) (s : Types.storage) : timestamp * bool =
  (Tezos.get_now(), s.bet_config.is_event_creation_paused)