// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BribeManager} from "../src/periphery/BribeManager.sol";
import {BointsApr} from "../src/periphery/BointsApr.sol";
contract Deploy is Script {
    function run() public {
        vm.startBroadcast();
        BointsApr bointsApr = new BointsApr(
            address(0x261cF8ccBf5023aE7D5219A136c31e8a86220FD3)
        );
        console.log("BointsApr deployed at", address(bointsApr));
        vm.stopBroadcast();
    }
}