// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {StakedBearnBGTCompounderClaimer} from "../src/StakedBearnBGTCompounderClaimer.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();

        StakedBearnBGTCompounderClaimer styBGTCompounderClaimer = new StakedBearnBGTCompounderClaimer(
            address(0x261cF8ccBf5023aE7D5219A136c31e8a86220FD3),
            address(0x6Fd7f15a0d7babe0A1a752564a591e1Cb6117F80),
            address(0x982940eBfC5caa2F5b5a82AAc2Dfa99F18BB7dA4)
        );

        console.log("StakedBearnBGTCompounderClaimer deployed at", address(styBGTCompounderClaimer));

        vm.stopBroadcast();
    }
}