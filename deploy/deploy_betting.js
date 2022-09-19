"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
exports.__esModule = true;
var utils_1 = require("@taquito/utils");
var signer_1 = require("@taquito/signer");
var taquito_1 = require("@taquito/taquito");
var dotenv = __importStar(require("dotenv"));
var betting_json_1 = __importDefault(require("../src/compiled/betting.json"));
var metadata_betting_json_1 = __importDefault(require("./metadata/metadata_betting.json"));
dotenv.config(({ path: __dirname + '/.env' }));
var rpc = process.env.TZ_RPC;
var Tezos = new taquito_1.TezosToolkit(rpc || '');
var prk = (process.env.ADMIN_PRK || '');
var signature = new signer_1.InMemorySigner(prk);
Tezos.setProvider({ signer: signature });
Tezos.tz
    .getBalance(process.env.ADMIN_ADDRESS || '')
    .then(function (balance) { return console.log("Signer balance : " + balance.toNumber() / 1000000 + " \uA729"); })["catch"](function (error) { return console.log(JSON.stringify(error)); });
var getOracle = function () { return __awaiter(void 0, void 0, void 0, function () {
    var args, address, _a;
    return __generator(this, function (_b) {
        switch (_b.label) {
            case 0:
                args = process.argv.slice(2);
                address = args[0];
                if (!(address !== undefined)) return [3 /*break*/, 1];
                _a = address;
                return [3 /*break*/, 3];
            case 1: return [4 /*yield*/, Promise.resolve().then(function () { return __importStar(require("../deployments/oracle")); })];
            case 2:
                _a = (_b.sent())["default"];
                _b.label = 3;
            case 3: return [2 /*return*/, _a];
        }
    });
}); };
var deploy = function () { return __awaiter(void 0, void 0, void 0, function () {
    function orig() {
        return __awaiter(this, void 0, void 0, function () {
            var betting_originated, error_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 3, , 4]);
                        return [4 /*yield*/, Tezos.contract.originate({
                                code: betting_json_1["default"],
                                storage: store
                            })];
                    case 1:
                        betting_originated = _a.sent();
                        console.log("Waiting for betting origination " + betting_originated.contractAddress + " to be confirmed...");
                        return [4 /*yield*/, betting_originated.confirmation(2)];
                    case 2:
                        _a.sent();
                        console.log('Confirmed betting origination : ', betting_originated.contractAddress);
                        console.log('tezos-client remember contract betting_betting ', betting_originated.contractAddress, ' --force');
                        return [3 /*break*/, 4];
                    case 3:
                        error_1 = _a.sent();
                        console.log(error_1);
                        return [3 /*break*/, 4];
                    case 4: return [2 /*return*/];
                }
            });
        });
    }
    var ORACLE_ADDRESS, init_bet_config_type, store;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0: return [4 /*yield*/, getOracle()];
            case 1:
                ORACLE_ADDRESS = _a.sent();
                console.log('Using the following Oracle address : ', ORACLE_ADDRESS);
                init_bet_config_type = {
                    is_betting_paused: false,
                    is_event_creation_paused: false,
                    min_bet_amount: 1000000,
                    retained_profit_quota: 10
                };
                store = {
                    manager: (process.env.ADMIN_ADDRESS || ''),
                    oracle_address: (ORACLE_ADDRESS || ''),
                    bet_config: init_bet_config_type,
                    events: (new (taquito_1.MichelsonMap)),
                    events_bets: (new (taquito_1.MichelsonMap)),
                    events_index: 0,
                    metadata: (taquito_1.MichelsonMap.fromLiteral({
                        '': utils_1.char2Bytes('tezos-storage:contents'),
                        contents: utils_1.char2Bytes(JSON.stringify(metadata_betting_json_1["default"]))
                    }))
                };
                orig();
                return [2 /*return*/];
        }
    });
}); };
deploy();
