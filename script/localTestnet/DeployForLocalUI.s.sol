// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Script, console, stdJson} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {IBeraVaultFactory} from "src/interfaces/IBeraVaultFactory.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";

import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";

import {BearnVaultFactory} from "src/BearnVaultFactory.sol";
import {BearnAuctionFactory} from "src/BearnAuctionFactory.sol";
import {BearnVaultManager} from "src/BearnVaultManager.sol";
import {BearnVoter} from "src/BearnVoter.sol";
import {BearnVoterManager} from "src/BearnVoterManager.sol";
import {BearnBGT} from "src/BearnBGT.sol";
import {BearnBGTFeeModule} from "src/BearnBGTFeeModule.sol";
import {StakedBearnBGT} from "src/StakedBearnBGT.sol";

import {BearnUIControlCentre} from "src/periphery/BearnUIControlCentre.sol";
import {BearnTips} from "src/periphery/BearnTips.sol";

import {DeployScript} from "script/Deployment.s.sol";

import {ERC20} from "@openzeppelin-yearn/contracts/token/ERC20/ERC20.sol";

contract LocalUIDeployment is DeployScript, StdCheats {
    using stdJson for string;

    address[] internal stakes;
    string[] internal nameOverrides;
    address[] internal tokensWithOracles;
    bytes32[] internal oracleIds;

    bool internal testing;

    function setUp() public override {
        testing = vm.envBool("TESTING");

        // reset fork
        if (testing) {
            vm.rpc(
                "hardhat_reset",
                '[{"forking": {"jsonRpcUrl": "https://rpc.berachain.com","blockNumber": 2198847}}]'
            );
        }

        console.log(block.number);

        // create a testnet wallet if needed
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        if (deployer == address(0)) {
            vm.rememberKey(
                vm.deriveKey(
                    "test test test test test test test test test test test junk",
                    0
                )
            );
            address[] memory wallets = vm.getWallets();
            deployer = wallets[0];
        }
        console.log("deployer", deployer);

        // deal some eth
        if (testing) {
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
        }

        // Read whitelisted addresss from configs
        string memory root = vm.projectRoot();
        string memory configs = vm.readFile(
            string.concat(root, "/script/configs/whitelistedStakes.json")
        );

        stakes = configs.readAddressArray(".tokens");
        nameOverrides = configs.readStringArray(".names");
        tokensWithOracles = configs.readAddressArray(".tokensWithOracles");
        oracleIds = configs.readBytes32Array(".oracleIds");

        super.setUp();
    }

    function run() public override {
        DeployedContracts memory deployedContracts = deploy();
        deployUIContracts(deployedContracts);
        deployVaults(deployedContracts);

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
            "styBGTCompounder",
            address(deployedContracts.styBGTCompounder)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "feeModule",
            address(deployedContracts.feeModule)
        );
        json = vm.serializeAddress(
            "EXPORTS",
            "treasury",
            address(deployedContracts.treasury)
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

    function deployUIContracts(DeployedContracts memory c) public {
        vm.startBroadcast(deployer);

        BearnUIControlCentre uiControl = new BearnUIControlCentre(
            address(c.authorizer),
            address(c.styBGT),
            address(c.vaultFactory)
        );

        BearnTips bearnTips = new BearnTips(address(c.authorizer));
        bearnTips.setTreasury(address(c.treasury));

        bool[] memory states = new bool[](stakes.length);
        for (uint256 i = 0; i < stakes.length; i++) {
            states[i] = true;
        }

        // whitelist stakes
        uiControl.adjustWhitelists(stakes, states);

        // override token names
        for (uint256 i = 0; i < stakes.length; i++) {
            uiControl.setNameOverride(stakes[i], nameOverrides[i]);
        }

        // record oracle IDs
        for (uint256 i = 0; i < tokensWithOracles.length; i++) {
            uiControl.setPythOracleId(tokensWithOracles[i], oracleIds[i]);
        }

        vm.stopBroadcast();

        string memory json = vm.serializeAddress(
            "EXPORTS",
            "uiControlCentre",
            address(uiControl)
        );

        json = vm.serializeAddress("EXPORTS", "bearnTips", address(bearnTips));

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

    function deployVaults(DeployedContracts memory c) public {
        vm.startBroadcast(deployer);

        for (uint i = 0; i < stakes.length; i++) {
            address stakeToken = stakes[i];
            console.log("stakeToken", stakeToken);
            IBeraVault beraVault = IBeraVault(
                IBeraVaultFactory(beraVaultFactory).getVault(stakeToken)
            );

            c.vaultFactory.createVaults(stakeToken);

            // get deployer some staking tokens

            // use beraVault as whale
            address tokenWhale = address(beraVault);

            // vm.prank(tokenWhale);
            // ERC20(stakeToken).transfer(deployer, 1000 ether);

            // need to use this workaround since forge script doesn't like using pranks
            // even if the destination is an anvil fork

            // reset deal some eth
            if (testing) {
                vm.rpc(
                    "hardhat_setBalance",
                    string.concat(
                        "[",
                        '"',
                        vm.toString(tokenWhale),
                        '","',
                        vm.toString(uint256(1000 ether)),
                        '"',
                        "]"
                    )
                );

                bytes memory data = abi.encodeCall(
                    ERC20.transfer,
                    (deployer, 1000 ether)
                );

                string memory params;
                params = vm.serializeAddress(
                    "params",
                    "to",
                    address(stakeToken)
                );
                params = vm.serializeAddress(
                    "params",
                    "from",
                    address(tokenWhale)
                );
                params = vm.serializeBytes("params", "data", data);
                params = vm.serializeBytes32(
                    "params",
                    "gas",
                    bytes32(uint256(1000000))
                );
                params = vm.serializeBytes32(
                    "params",
                    "gasPrice",
                    bytes32(tx.gasprice)
                );
                params = vm.serializeBytes32("params", "value", bytes32(0));

                vm.rpc("eth_sendTransaction", string.concat("[", params, "]"));
                vm.rpc("hardhat_mine", "[]");
            }
        }

        vm.stopBroadcast();
    }
}
