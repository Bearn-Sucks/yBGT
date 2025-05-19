// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BribeManager} from "../src/periphery/BribeManager.sol";
import {BointsApr} from "../src/periphery/BointsApr.sol";
import {yBGTReceiver} from "../src/periphery/yBGTReceiver.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();
        
        yBGTReceiver receiver = new yBGTReceiver(
            0x261cF8ccBf5023aE7D5219A136c31e8a86220FD3,
            address(0x6f8cEAF347dA79287e49A5C9F0a03b20BDFCB7D3),
            address(0x982940eBfC5caa2F5b5a82AAc2Dfa99F18BB7dA4),
            address(0xBEA7400025a9d1319CE333B5822f92D45C309EA4),
            8000,
            0x1d3C155281fa67c4f21d9654DD31Af3E288487c6
        );

        console.log("yBGTReceiver deployed at", address(receiver));
        vm.stopBroadcast();
    }
}