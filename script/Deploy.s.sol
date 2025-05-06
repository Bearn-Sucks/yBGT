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

        console.log("Honey APR ", bointsApr.getHoneyBointsApr(18750000));

        console.log("YBera APR ", bointsApr.getYBeraBointsApr(18750000));

        console.log("LP APR ", bointsApr.getLPBointsApr(18750000));

        console.log("Staked Boints APR ", bointsApr.getStakedBointsApr(18750000));
        vm.stopBroadcast();
    }
}