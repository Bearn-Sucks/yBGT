// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Script, console, stdJson} from "forge-std/Script.sol";

import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";
import {Treasury} from "@bearn/governance/contracts/Treasury.sol";

import {BearnVaultFactory} from "src/BearnVaultFactory.sol";
import {BearnAuctionFactory} from "src/BearnAuctionFactory.sol";
import {BearnVaultManager} from "src/BearnVaultManager.sol";
import {BearnVoter} from "src/BearnVoter.sol";
import {BearnVoterManager} from "src/BearnVoterManager.sol";
import {BearnBGT} from "src/BearnBGT.sol";
import {BearnBGTFeeModule} from "src/BearnBGTFeeModule.sol";
import {StakedBearnBGT} from "src/StakedBearnBGT.sol";
import {StakedBearnBGTCompounder} from "src/StakedBearnBGTCompounder.sol";

import {IBearnVault} from "src/interfaces/IBearnVault.sol";

contract DeployScript is Script {
    using stdJson for string;

    address msig;
    address deployer;

    address treasury;

    address constant bgt = 0x656b95E550C07a9ffe548bd4085c72418Ceb1dba;
    address constant bgtStaker = 0x44F07Ce5AfeCbCC406e6beFD40cc2998eEb8c7C6;
    address constant wbera = 0x6969696969696969696969696969696969696969;
    address constant beraGovernance =
        0x4f4A5c2194B8e856b7a05B348F6ba3978FB6f6D5;
    address constant beraVaultFactory =
        0x94Ad6Ac84f6C6FbA8b8CCbD71d9f4f101def52a8;
    address constant honey = 0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce;

    address constant yearnPermissionlessKeeper =
        0x52605BbF54845f520a3E94792d019f62407db2f8;

    struct DeployedContracts {
        BearnAuthorizer authorizer;
        Treasury treasury;
        BearnVaultManager vaultManager;
        BearnVaultFactory vaultFactory;
        BearnVoter voter;
        BearnVoterManager voterManager;
        BearnAuctionFactory auctionFactory;
        BearnBGT yBGT;
        StakedBearnBGT styBGT;
        StakedBearnBGTCompounder styBGTCompounder;
        BearnBGTFeeModule feeModule;
    }

    function setUp() public virtual {
        // Read msig address from configs
        string memory root = vm.projectRoot();
        string memory configs = vm.readFile(
            string.concat(root, "/script/configs/bearnManagementAddresses.json")
        );

        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        if (deployer == address(0)) {
            address[] memory wallets = vm.getWallets();
            deployer = wallets[0];
        }
        console.log("deployer", deployer);

        msig = configs.readAddress(".multisig");

        if (msig == address(0)) {
            msig = deployer;
            treasury = deployer;
        } else {
            treasury = msig;
        }
    }

    function run() public virtual {
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
                "/script/output/mainnet/mainnet-",
                vm.toString(block.timestamp),
                ".json"
            )
        );
    }

    function deploy()
        public
        returns (DeployedContracts memory deployedContracts)
    {
        vm.startBroadcast(deployer);

        ////////////////////////
        /// Deploy contracts ///
        ////////////////////////

        deployedContracts.authorizer = new BearnAuthorizer();

        deployedContracts.authorizer.initialize(deployer, deployer);

        deployedContracts.voter = new BearnVoter(
            address(deployedContracts.authorizer),
            bgt,
            wbera,
            beraGovernance,
            treasury
        );

        deployedContracts.feeModule = new BearnBGTFeeModule(
            address(deployedContracts.authorizer),
            500, // 5%
            500,
            500,
            0,
            false
        );

        deployedContracts.yBGT = new BearnBGT(
            address(deployedContracts.authorizer),
            beraVaultFactory,
            address(deployedContracts.voter),
            address(deployedContracts.feeModule),
            treasury
        );

        deployedContracts.vaultFactory = new BearnVaultFactory(
            address(deployedContracts.authorizer),
            beraVaultFactory,
            address(deployedContracts.yBGT),
            yearnPermissionlessKeeper
        );

        deployedContracts.vaultManager = new BearnVaultManager(
            address(deployedContracts.authorizer),
            msig,
            address(deployedContracts.vaultFactory),
            address(deployedContracts.voter)
        );

        deployedContracts.styBGT = new StakedBearnBGT(
            address(deployedContracts.voter),
            address(deployedContracts.vaultManager),
            address(deployedContracts.yBGT),
            honey
        );

        deployedContracts.styBGTCompounder = new StakedBearnBGTCompounder(
            address(deployedContracts.styBGT),
            address(deployedContracts.vaultManager),
            honey
        );

        deployedContracts.treasury = new Treasury(
            address(deployedContracts.authorizer),
            address(deployedContracts.yBGT),
            address(deployedContracts.styBGT)
        );

        deployedContracts.voterManager = new BearnVoterManager(
            address(deployedContracts.authorizer),
            bgt,
            bgtStaker,
            wbera,
            honey,
            beraGovernance,
            address(deployedContracts.voter),
            address(deployedContracts.styBGT)
        );

        deployedContracts.auctionFactory = new BearnAuctionFactory(
            wbera,
            address(deployedContracts.yBGT),
            address(deployedContracts.vaultFactory)
        );

        // Initialize Voter
        deployedContracts.voter.setVoterManager(
            address(deployedContracts.voterManager)
        );

        // Set up Vault Factory
        deployedContracts.vaultFactory.setVaultManager(
            address(deployedContracts.vaultManager)
        );

        deployedContracts.vaultFactory.setAuctionFactory(
            address(deployedContracts.auctionFactory)
        );

        // Set Up Fee Module
        deployedContracts.feeModule.setBearnFactory(
            address(deployedContracts.vaultFactory)
        );

        // Grant redeemer role to yBGT
        deployedContracts.authorizer.grantRole(
            deployedContracts.voter.REDEEMER_ROLE(),
            address(deployedContracts.yBGT)
        );

        // Accept styBGT Compounder's Auction's governance
        deployedContracts.vaultManager.registerAuction(
            address(deployedContracts.styBGTCompounder.auction())
        );

        // Transfer styBGT and styBGTCompounder's management to vault manager
        IBearnVault(address(deployedContracts.styBGT)).setPendingManagement(
            address(deployedContracts.vaultManager)
        );
        IBearnVault(address(deployedContracts.styBGTCompounder))
            .setPendingManagement(address(deployedContracts.vaultManager));
        deployedContracts.vaultManager.registerVault(
            address(deployedContracts.styBGT)
        );
        deployedContracts.vaultManager.registerVault(
            address(deployedContracts.styBGTCompounder)
        );

        // Transfer treasury to the smart contract
        bytes32 TREASURY_APPROVER_ROLE = deployedContracts
            .treasury
            .TREASURY_APPROVER_ROLE();
        bytes32 TREASURY_RETRIEVER_ROLE = deployedContracts
            .treasury
            .TREASURY_RETRIEVER_ROLE();

        if (
            !deployedContracts.authorizer.hasRole(TREASURY_APPROVER_ROLE, msig)
        ) {
            deployedContracts.authorizer.grantRole(
                TREASURY_APPROVER_ROLE,
                msig
            );
        }
        if (
            !deployedContracts.authorizer.hasRole(TREASURY_RETRIEVER_ROLE, msig)
        ) {
            deployedContracts.authorizer.grantRole(
                TREASURY_RETRIEVER_ROLE,
                msig
            );
        }

        deployedContracts.yBGT.setFeeRecipient(
            address(deployedContracts.treasury)
        );
        address[] memory vaults = new address[](2);
        vaults[0] = address(deployedContracts.styBGT);
        vaults[1] = address(deployedContracts.styBGTCompounder);
        deployedContracts.vaultManager.syncVaultSettings(vaults);
        deployedContracts.voter.setTreasury(
            address(deployedContracts.treasury)
        );

        vm.stopBroadcast();
    }
}
