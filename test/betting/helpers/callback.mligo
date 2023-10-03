#import "../../../src/contracts/cameligo/betting/callback/main.mligo" "Callback"

(* Some types for readability *)
type taddr = (Callback parameter_of, Callback.storage) typed_address
type contr = Callback parameter_of contract
type originated = {
    addr: address;
    taddr: taddr;
    contr: contr;
}

let plain_timestamp : timestamp = ("1970-01-01T00:00:01Z" : timestamp)

(* Base Callback storage *)
let base_storage (bettingAddr : address) : Callback.storage = {
    name                = "";
    videogame           = "";
    begin_at            = plain_timestamp + 2048;
    end_at              = plain_timestamp + 4096;
    modified_at         = plain_timestamp;
    opponents           = { team_one = ""; team_two = ""};
    game_status         = Ongoing;
    start_bet_time      = plain_timestamp + 360;
    closed_bet_time     = plain_timestamp + 3072;
    bets_team_one       = (Map.empty : (address, tez) map);
    bets_team_one_index = 0n;
    bets_team_one_total = 0mutez;
    bets_team_two       = (Map.empty : (address, tez) map);
    bets_team_two_index = 0n;
    bets_team_two_total = 0mutez;
    meta                = (Map.empty : (string, bytes) map);
    bettingAddr         = bettingAddr;
}

let originate_from_file (initial_storage : Callback.storage) : originated =
    let betting_path           = "../../../src/contracts/cameligo/betting/callback/main.mligo" in
    let orig  = Test.originate_from_file betting_path initial_storage 0mutez in
    let callback_contract      = Test.to_contract orig.addr in
    let callback_addr          = Test.to_address orig.addr in
    {
        contr=callback_contract;
        taddr=orig.addr;
        addr=callback_addr;
    }
