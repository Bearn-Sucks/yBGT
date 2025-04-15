// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VoterOperator} from "../src/periphery/VoterOperator.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();

        VoterOperator voterOperator = new VoterOperator(
            address(0x261cF8ccBf5023aE7D5219A136c31e8a86220FD3),
            address(0xf64B67875F299e1Ed49F2aA15B9C38a8641d2BA9)
        );

        console.log("VoterOperator deployed at", address(voterOperator));

        vm.stopBroadcast();
    }
}