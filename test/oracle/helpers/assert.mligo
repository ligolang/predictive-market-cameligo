#import "../../../src/contracts/cameligo/oracle/types.mligo" "Types"
#import "../../../src/contracts/cameligo/oracle/main.mligo" "Oracle"
#import "../../../src/contracts/cameligo/oracle/callback/main.mligo" "Callback"

(* Assert contract result is successful *)
let tx_success (res: test_exec_result) : unit =
    match res with
        | Fail (Rejected (error,_)) -> let () = Test.log(error) in failwith "Transaction should not fail"
        | Fail _ -> failwith "Transaction should not fail"
        | Success(_) -> ()

(* Assert contract call results in failwith with given string *)
let string_failure (res : test_exec_result) (p_expected : string) : unit =
    let expected = Test.eval p_expected in
    match res with
        | Fail (Rejected (actual, _)) -> assert (actual = expected)
        | Fail (Balance_too_low _) -> failwith "Contract failed: Balance too low"
        | Fail (Other s) -> failwith s
        | Success _ -> failwith "Transaction should fail"

(* Assert Manager parameter with expected result *)
let manager (ctr_taddr : (Oracle parameter_of, Types.storage) typed_address) (expected : address) : unit =
    let ctr_storage : Types.storage = Test.get_storage(ctr_taddr) in
    let ctr_value : address = (ctr_storage.manager) in
    assert (ctr_value = expected)

(* Assert Signer parameter with expected result *)
let signer (ctr_taddr : (Oracle parameter_of, Types.storage) typed_address) (expected : address) : unit =
    let ctr_storage : Types.storage = Test.get_storage(ctr_taddr) in
    let ctr_value : address = (ctr_storage.signer) in
    assert (ctr_value = expected)

(* Assert isPaused parameter with expected result *)
let ispaused (ctr_taddr : (Oracle parameter_of, Types.storage) typed_address) (expected : bool) : unit =
    let ctr_storage : Types.storage = Test.get_storage(ctr_taddr) in
    let ctr_value : bool = (ctr_storage.isPaused) in
    assert (ctr_value = expected)

(* Assert isPaused parameter with expected result *)
let events_map (ctr_taddr : (Oracle parameter_of, Types.storage) typed_address) (expected : (nat, Types.event_type) map) : unit =
    let ctr_storage = Test.get_storage(ctr_taddr) in
    let ctr_value : (nat, Types.event_type) map = (ctr_storage.events) in
    assert (ctr_value = expected)

let event (taddr : (Callback parameter_of, Callback.storage) typed_address) (expected_event : Types.event_type) : unit =
    let storage = Test.get_storage(taddr) in
    let () = assert(storage.name = expected_event.name) in
    let () = assert(storage.videogame = expected_event.videogame) in
    let () = assert(storage.begin_at = expected_event.begin_at) in
    let () = assert(storage.end_at = expected_event.end_at) in
    let () = assert(storage.modified_at = expected_event.modified_at) in
    let () = assert(storage.opponents = expected_event.opponents) in
    let () = assert(storage.game_status = expected_event.game_status) in
    ()
