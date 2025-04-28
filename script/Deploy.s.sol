// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {BearnVoterManager} from "../src/BearnVoterManager.sol";
import {console} from "forge-std/console.sol";
import {StakedBearnHoney} from "../src/StakedBearnHoney.sol";
import {YHoneyZapper} from "../src/periphery/yHoneyZapper.sol";
contract Deploy is Script {
    address public yHONEY = 0xC82971BcFF09171e16Ac08AEE9f4EA3fB16C3BDC;
    function run() public {
        vm.startBroadcast();

        YHoneyZapper yHoneyZapper = new YHoneyZapper();

        console.log("YHoneyZapper deployed at", address(yHoneyZapper));
        vm.stopBroadcast();
    }
}
