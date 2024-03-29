#import "../../../src/contracts/cameligo/oracle/callback/main.mligo" "Callback"

(* Some types for readability *)
type taddr = (Callback parameter_of, Callback.storage) typed_address
type contr = Callback parameter_of contract
type originated = {
    addr: address;
    taddr: taddr;
    contr: contr;
}

let plain_timestamp : timestamp = ("1970-01-01T00:00:01Z" : timestamp)

type game_status = Ongoing | Team1Win| Team2Win | Draw

(* Base Callback storage *)
let base_storage : Callback.storage = {
    name = "";
    videogame = "";
    begin_at = plain_timestamp + 2000;
    end_at = plain_timestamp + 4000;
    modified_at = plain_timestamp;
    opponents = { team_one = ""; team_two = ""};
    game_status = Ongoing;
    meta = (Map.empty : (string, bytes) map);
}

let originate_from_file (initial_storage : Callback.storage) : originated =
    let oracle_path = "../../../src/contracts/cameligo/oracle/callback/main.mligo" in
    let orig = Test.originate_from_file oracle_path initial_storage 0mutez in
    let callback_contract = Test.to_contract orig.addr in
    let callback_addr = Test.to_address orig.addr in
    {
        contr=callback_contract;
        taddr=orig.addr;
        addr=callback_addr;
    }
