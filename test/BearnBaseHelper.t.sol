// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import "forge-std/Test.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// import {RewardVaultTest as BeraRewardVaultTest} from "@berachain/test/pol/RewardVault.t.sol";
import {POLTest as BeraHelper} from "@berachain/test/pol/POL.t.sol";

import {IBaseAuctioneer} from "@yearn/tokenized-strategy-periphery/Bases/Auctioneer/IBaseAuctioneer.sol";

import {BearnBGT} from "src/BearnBGT.sol";
import {BearnVoter} from "src/BearnVoter.sol";
import {BearnVoterManager} from "src/BearnVoterManager.sol";
import {BearnVaultFactory} from "src/BearnVaultFactory.sol";
import {BearnVault} from "src/BearnVault.sol";
import {BearnVaultManager} from "src/BearnVaultManager.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnCompoundingVault} from "src/interfaces/IBearnCompoundingVault.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";

import {BearnBGTFeeModule} from "src/BearnBGTFeeModule.sol";

abstract contract BearnBaseHelper is BeraHelper {
    address internal bearnManager = makeAddr("bearnManager");
    address internal protocolFeeRecipient = makeAddr("protocolFeeRecipient");
    address internal user = makeAddr("user");
    address internal user2 = makeAddr("user2");
    address internal treasury = makeAddr("treasury");

    ProxyAdmin internal proxyAdmin;
    BearnVaultManager internal bearnVaultManager;
    IBeraVault internal beraVault;
    BearnBGT internal yBGT;
    BearnBGTFeeModule internal feeModule;
    BearnVoter internal bearnVoter;
    BearnVoterManager internal bearnVoterManager;
    BearnVaultFactory internal bearnVaultFactory;
    IBearnVault internal bearnVault;
    IBearnCompoundingVault internal bearnCompoundingVault;
    IBaseAuctioneer internal bearnCompoundingVaultAuction;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual override {
        super.setUp();

        // act as bera governance to make a new bera vault
        vm.prank(governance);
        beraVault = IBeraVault(factory.createRewardVault(address(wbera)));
        vm.prank(governance);
        beraVault.setRewardsDuration(3);
        deal(address(bgt), address(distributor), 1000 ether);

        vm.startPrank(bearnManager);
        vm.deal(bearnManager, 100 ether);

        // Deploy CoW contracts
        deployCodeTo(
            "MockCoWSettlement",
            0x9008D19f58AAbD9eD0D60971565AA8510560ab41
        );

        // Deploy yearn contracts
        address protocolFees = deployCode(
            "MockProtocolFees",
            abi.encode(protocolFeeRecipient)
        );
        deployCodeTo(
            "TokenizedStrategy",
            abi.encode(protocolFees),
            0xD377919FA87120584B21279a491F82D5265A139c
        );
        vm.label(
            0xD377919FA87120584B21279a491F82D5265A139c,
            "TokenizedStrategy"
        );

        deployCodeTo(
            "AuctionFactory",
            0xa076c247AfA44f8F006CA7f21A4EF59f7e4dc605
        );
        vm.label(0xa076c247AfA44f8F006CA7f21A4EF59f7e4dc605, "AuctionFactory");

        // Deploy Bearn contracts
        // Deploy Bearn Vault Factory
        bearnVaultFactory = new BearnVaultFactory(
            bearnManager,
            address(factory)
        );

        // Deploy Bearn Voter

        bearnVoter = new BearnVoter(
            address(bgt),
            address(wbera),
            address(governance),
            address(treasury)
        );

        // Deploy Bearn Voter Manager
        bearnVoterManager = new BearnVoterManager(
            address(bgt),
            address(wbera),
            address(governance),
            address(bearnVoter)
        );

        // Deploy Fee Module
        feeModule = new BearnBGTFeeModule(0, 0, false);

        // Deploy yBGT
        yBGT = new BearnBGT(
            bearnManager,
            address(factory),
            address(bearnVoter),
            address(feeModule)
        );

        // Deploy Bearn Vault Manager
        bearnVaultManager = new BearnVaultManager(address(bearnVaultFactory));

        // Initialize and pass ownership
        bearnVaultFactory.initialize(address(yBGT));
        bearnVaultFactory.setVaultManager(address(bearnVaultManager));

        // Grant roles on Voter
        bearnVoter.grantRole(
            bearnVoter.MANAGER_ROLE(),
            address(bearnVoterManager)
        );
        bearnVoter.grantRole(bearnVoter.REDEEMER_ROLE(), address(yBGT));

        // Create vaults to test with
        (
            address _bearnCompoundingVault,
            address _bearnVault
        ) = bearnVaultFactory.createVaults(address(wbera));

        (bearnCompoundingVault, bearnVault) = (
            IBearnCompoundingVault(_bearnCompoundingVault),
            IBearnVault(_bearnVault)
        );

        bearnCompoundingVaultAuction = IBaseAuctioneer(
            bearnCompoundingVault.auction()
        );

        vm.stopPrank();

        // set up user balances
        vm.startPrank(user);
        vm.deal(user, 100 ether);
        wbera.deposit{value: 10 ether}();
        // set up approvals
        wbera.approve(address(bearnVault), type(uint256).max);
        wbera.approve(address(bearnCompoundingVault), type(uint256).max);

        vm.stopPrank();

        // set up user2 balances
        vm.startPrank(user2);
        vm.deal(user2, 100 ether);
        wbera.deposit{value: 10 ether}();
        // set up approvals
        wbera.approve(address(bearnVault), type(uint256).max);
        wbera.approve(address(bearnCompoundingVault), type(uint256).max);

        vm.stopPrank();
    }

    function _pushRewardsAndReport(
        address _bearnVault,
        uint256 amount
    ) internal {
        // add BGT to bera reward vault
        vm.prank(address(distributor));
        bgt.approve(address(beraVault), type(uint256).max);
        vm.prank(address(distributor));
        beraVault.notifyRewardAmount(valData.pubkey, amount);

        vm.warp(block.timestamp + 3);

        vm.prank(bearnManager);
        bearnVaultFactory.report(_bearnVault);
    }
}
