#import "types.mligo" "Types"
#import "assert.mligo" "Assert"
#import "errors.mligo" "Errors"
#import "callback/main.mligo" "Callback"

[@entry] let changeManager (new_manager : address)( s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  let _ = Assert.not_previous_manager new_manager s.manager in
  (([] : operation list), {s with manager = new_manager})

[@entry] let switchPause (_ : unit) (s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager (Tezos.get_sender()) s.manager in
  (([] : operation list), {s with isPaused = (not s.isPaused)})

[@entry] let changeSigner (new_signer : address)( s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager__or_signer (Tezos.get_sender()) s.manager s.signer in
  let _ = Assert.not_previous_signer new_signer s.signer in
  (([] : operation list), {s with signer = new_signer})

[@entry] let addEvent (new_event : Types.event_type)(s : Types.storage) : (operation list * Types.storage) =
  let _ = Assert.is_manager__or_signer (Tezos.get_sender()) s.manager s.signer in
  let new_events : (nat, Types.event_type) map = (Map.add (s.events_index) new_event s.events) in
  (([] : operation list), {s with events = new_events; events_index = (s.events_index + 1n)})

[@entry] let getEvent (callback_asked_param : Types.callback_asked_parameter) (s : Types.storage) : (operation list * Types.storage) =
  let { requested_event_id; callback } = callback_asked_param in
  let cbk_event =
    match Map.find_opt requested_event_id s.events with
      Some event -> event
    | None -> (failwith Errors.no_event_id)
    in
  let destination : Callback.requested_event_param contract =
  match (Tezos.get_entrypoint_opt "%saveEvent" callback : Callback.requested_event_param contract option) with
    None -> failwith("Unknown contract")
  | Some ctr -> ctr
  in
  let op : operation = Tezos.transaction cbk_event 0mutez destination in
  ([op], s)

[@entry] let updateEvent (updated_event_param : Types.update_event_parameter)(s : Types.storage) : (operation list * Types.storage) =
  let { updated_event_id ; updated_event} = updated_event_param in
  let _ = Assert.is_manager__or_signer (Tezos.get_sender()) s.manager s.signer in
  let _ : Types.event_type =
    match Map.find_opt updated_event_id s.events with
      Some event -> event
    | None -> (failwith Errors.no_event_id)
  in
  let new_events : (nat, Types.event_type) map = Map.update updated_event_id (Some(updated_event)) s.events in
  (([] : operation list), {s with events = new_events})


[@view]
let getManager (_ : unit) (s : Types.storage) : timestamp * address =
  (Tezos.get_now(), s.manager)

[@view]
let getSigner (_ : unit) (s : Types.storage) : timestamp * address =
  (Tezos.get_now(), s.signer)

[@view]
let getStatus (_ : unit) (s : Types.storage) : timestamp * bool =
  (Tezos.get_now(), s.isPaused)