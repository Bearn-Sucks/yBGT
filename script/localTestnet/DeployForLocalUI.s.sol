// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Script, console, stdJson} from "forge-std/Script.sol";

import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";

import {BearnVaultFactory} from "src/BearnVaultFactory.sol";
import {BearnAuctionFactory} from "src/BearnAuctionFactory.sol";
import {BearnVaultManager} from "src/BearnVaultManager.sol";
import {BearnVoter} from "src/BearnVoter.sol";
import {BearnVoterManager} from "src/BearnVoterManager.sol";
import {BearnBGT} from "src/BearnBGT.sol";
import {BearnBGTFeeModule} from "src/BearnBGTFeeModule.sol";
import {StakedBearnBGT} from "src/StakedBearnBGT.sol";

import {DeployScript} from "script/Deployment.s.sol";

contract LocalUIDeployment is DeployScript {
    function setUp() public override {
        // reset fork
        vm.rpc(
            "hardhat_reset",
            '[{"forking": {"jsonRpcUrl": "https://rpc.berachain.com","blockNumber": 2020603}}]'
        );

        // create a testnet wallet
        vm.rememberKey(
            vm.deriveKey(
                "test test test test test test test test test test test junk",
                0
            )
        );
        address[] memory wallets = vm.getWallets();
        deployer = wallets[0];
        console.log("deployer", deployer);

        // reset deal some eth
        vm.rpc(
            "hardhat_setBalance",
            string.concat(
                "[",
                '"',
                vm.toString(deployer),
                '","',
                vm.toString(uint256(1000 ether)),
                '"',
                "]"
            )
        );

        super.setUp();
    }

    function run() public override {
        DeployedContracts memory deployedContracts = deploy();

        ////////////////////////
        /// export addresses ///
        ////////////////////////

        string memory json;
        json = vm.serializeAddress(
            "EXPORTS",
            "authorizer",
            address(deployedContracts.authorizer)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "vaultManager",
            address(deployedContracts.vaultManager)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "vaultFactory",
            address(deployedContracts.vaultFactory)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "voter",
            address(deployedContracts.voter)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "voterManager",
            address(deployedContracts.voterManager)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "auctionFactory",
            address(deployedContracts.auctionFactory)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "yBGT",
            address(deployedContracts.yBGT)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "styBGT",
            address(deployedContracts.styBGT)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "feeModule",
            address(deployedContracts.feeModule)
        );

        vm.writeJson(
            json,
            string.concat(
                vm.projectRoot(),
                "/script/output/localUI/localUI-",
                vm.toString(block.timestamp),
                ".json"
            )
        );
    }
}
