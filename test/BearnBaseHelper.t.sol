// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

// import "forge-std/Test.sol";

// import {RewardVaultTest as BeraRewardVaultTest} from "@berachain/test/pol/RewardVault.t.sol";
import {POLTest as BeraHelper} from "@berachain/test/pol/POL.t.sol";

import {BearnBGT} from "src/BearnBGT.sol";
import {BearnVoter} from "src/BearnVoter.sol";
import {BearnVaultFactory} from "src/BearnVaultFactory.sol";
import {BearnVault} from "src/BearnVault.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnCompoundingVault} from "src/interfaces/IBearnCompoundingVault.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";

abstract contract BearnBaseHelper is BeraHelper {
    address internal bearnManager = makeAddr("bearnManager");
    address internal user = makeAddr("user");

    IBeraVault internal beraVault;
    BearnBGT internal yBGT;
    BearnVoter internal bearnVoter;
    BearnVaultFactory internal bearnVaultFactory;
    IBearnVault internal bearnVault;
    IBearnCompoundingVault internal bearnCompoundingVault;

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

        // Deploy yearn contracts
        deployCodeTo(
            "TokenizedStrategy",
            abi.encode(address(0)),
            0xD377919FA87120584B21279a491F82D5265A139c
        );
        vm.label(
            0xD377919FA87120584B21279a491F82D5265A139c,
            "TokenizedStrategy"
        );

        // Deploy contracts
        yBGT = new BearnBGT(bearnManager);
        bearnVaultFactory = new BearnVaultFactory(
            address(yBGT),
            address(factory)
        );
        bearnVoter = new BearnVoter(address(bearnVaultFactory));

        // initialize contracts
        yBGT.initialize(address(factory), address(bearnVoter));

        (
            address _bearnCompoundingVault,
            address _bearnVault
        ) = bearnVaultFactory.createVaults(address(wbera));

        (bearnCompoundingVault, bearnVault) = (
            IBearnCompoundingVault(_bearnCompoundingVault),
            IBearnVault(_bearnVault)
        );

        vm.stopPrank();
    }
}
