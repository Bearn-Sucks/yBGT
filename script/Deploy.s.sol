// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {BearnVoterManager} from "../src/BearnVoterManager.sol";
import {console} from "forge-std/console.sol";
import {StakedBearnBera} from "../src/StakedBearnBera.sol";

contract Deploy is Script {
    address public ybera = 0x982940eBfC5caa2F5b5a82AAc2Dfa99F18BB7dA4;
    function run() public {
        vm.startBroadcast();

        StakedBearnBera styBera = new StakedBearnBera(
            ybera
        );

        console.log("StakedBearnBera deployed at", address(styBera));
        vm.stopBroadcast();
    }
}
