// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

// import {RewardVaultTest as BeraRewardVaultTest} from "@berachain/test/pol/RewardVault.t.sol";
import {POLTest as BeraHelper} from "@berachain/test/pol/POL.t.sol";

import {IBaseAuctioneer} from "@yearn/tokenized-strategy-periphery/Bases/Auctioneer/IBaseAuctioneer.sol";

import {Keeper} from "src/mock/MockKeeper.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";
import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";

import {BearnBGT} from "src/BearnBGT.sol";
import {BearnVoter} from "src/BearnVoter.sol";
import {BearnVoterManager} from "src/BearnVoterManager.sol";
import {BearnVaultFactory} from "src/BearnVaultFactory.sol";
import {BearnAuctionFactory} from "src/BearnAuctionFactory.sol";
import {BearnVault} from "src/BearnVault.sol";
import {BearnVaultManager} from "src/BearnVaultManager.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {StakedBearnBGT} from "src/StakedBearnBGT.sol";
import {StakedBearnBGTCompounder} from "src/StakedBearnBGTCompounder.sol";

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
    address internal timelock = makeAddr("timelock");

    MockERC20 internal honey;

    Keeper internal keeper;

    BearnAuthorizer internal authorizer;
    BearnVaultManager internal bearnVaultManager;
    IBeraVault internal beraVault;
    BearnBGT internal yBGT;
    BearnBGTFeeModule internal feeModule;
    BearnVoter internal bearnVoter;
    BearnVoterManager internal bearnVoterManager;
    BearnVaultFactory internal bearnVaultFactory;
    BearnAuctionFactory internal bearnAuctionFactory;
    IBearnVault internal bearnVault;
    IBearnCompoundingVault internal bearnCompoundingVault;
    IBaseAuctioneer internal bearnCompoundingVaultAuction;
    StakedBearnBGT internal styBGT;
    StakedBearnBGTCompounder internal styBGTCompounder;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual override {
        super.setUp();

        // act as bera governance to make a new bera vault
        vm.prank(governance);
        beraVault = IBeraVault(factory.createRewardVault(address(wbera)));
        vm.prank(governance);
        beraVault.setRewardsDuration(3);
        deal(address(bgt), address(distributor), 1000 ether);
        honey = new MockERC20();
        honey.initialize("HONEY", "HONEY", 18);

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
            0xCfA510188884F199fcC6e750764FAAbE6e56ec40
        );
        vm.label(0xa076c247AfA44f8F006CA7f21A4EF59f7e4dc605, "AuctionFactory");

        keeper = Keeper(0x52605BbF54845f520a3E94792d019f62407db2f8);

        deployCodeTo("Keeper", address(keeper));
        vm.label(address(keeper), "PermissionlessKeeper");

        // Deploy Bearn contracts

        // Deploy Bearn Authorizer
        authorizer = new BearnAuthorizer();

        authorizer.initialize(bearnManager, bearnManager);

        // Deploy Bearn Voter
        bearnVoter = new BearnVoter(
            address(authorizer),
            address(bgt),
            address(wbera),
            address(governance),
            address(treasury)
        );

        // Deploy Fee Module
        feeModule = new BearnBGTFeeModule(
            address(authorizer),
            0,
            0,
            0,
            0,
            false
        );

        // Deploy yBGT
        yBGT = new BearnBGT(
            address(authorizer),
            address(factory),
            address(bearnVoter),
            address(feeModule),
            address(treasury)
        );

        // Deploy Bearn Vault Factory
        bearnVaultFactory = new BearnVaultFactory(
            address(authorizer),
            address(factory),
            address(yBGT),
            0x52605BbF54845f520a3E94792d019f62407db2f8 // yearn permissionless keeper
        );

        // Deploy Bearn Vault Manager
        bearnVaultManager = new BearnVaultManager(
            address(authorizer),
            address(operator),
            address(bearnVaultFactory),
            address(bearnVoter)
        );

        // Deploy Bearn Auction Factory
        bearnAuctionFactory = new BearnAuctionFactory(
            address(wbera),
            address(yBGT),
            address(bearnVaultFactory)
        );

        // Register Bearn Auction Factory
        bearnVaultFactory.setAuctionFactory(address(bearnAuctionFactory));

        // Deploy styBGT
        styBGT = new StakedBearnBGT(
            address(bearnVoter),
            address(bearnVaultManager),
            address(yBGT),
            address(honey)
        );

        styBGTCompounder = new StakedBearnBGTCompounder(
            address(styBGT),
            address(bearnVaultManager),
            address(honey)
        );

        // Accept styBGT Compounder's Auction's governance
        bearnVaultManager.registerAuction(address(styBGTCompounder.auction()));

        // Deploy Bearn Voter Manager
        bearnVoterManager = new BearnVoterManager(
            address(authorizer),
            address(bgt),
            address(bgtStaker),
            address(wbera),
            address(honey),
            address(governance),
            address(bearnVoter),
            address(styBGT)
        );

        // Initialize Voter
        bearnVoter.setVoterManager(address(bearnVoterManager));

        // Initialize Fee Module
        feeModule.setBearnFactory(address(bearnVaultFactory));

        // Pass ownership of Vault Factory
        bearnVaultFactory.setVaultManager(address(bearnVaultManager));

        // Grant redeemer role to yBGT
        authorizer.grantRole(bearnVoter.REDEEMER_ROLE(), address(yBGT));

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
        vm.roll(block.number + 1);

        keeper.report(_bearnVault);
    }
}
