// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.28;

import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {BearnBaseHelper, MockERC20, IBeraVault} from "./BearnBaseHelper.t.sol";
import {YBgtClaimer} from "src/periphery/YBgtClaimer.sol";

contract YBgtClaimerTest is BearnBaseHelper {
    YBgtClaimer public claimer;

    event AutoClaimSet(address indexed user, address indexed vault, bool autoClaim);

    function setUp() public override {
        super.setUp();

        // Deploy the claimer
        claimer = new YBgtClaimer(
            address(authorizer),
            address(styBGTCompounder),
            address(bearnVaultFactory)
        );

        // Set up claimer as reward recipient for users
        vm.prank(user);
        bearnVault.setClaimForSelf(address(claimer));

        vm.prank(address(bearnVaultManager));
        bearnVault.setClaimFor(user2, address(claimer));

        // Setup initial deposits and rewards
        vm.startPrank(user);
        wbera.approve(address(bearnVault), type(uint256).max);
        bearnVault.deposit(1 ether, user);
        vm.stopPrank();

        vm.startPrank(user2);
        wbera.approve(address(bearnVault), type(uint256).max);
        bearnVault.deposit(1 ether, user2);
        vm.stopPrank();
    }

    function testBasicClaim() public {
        // Push rewards
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 initialBalance = yBGT.balanceOf(user);
        
        address[] memory vaults = new address[](1);
        vaults[0] = address(bearnVault);

        vm.prank(user);
        claimer.claim(vaults);

        assertGt(yBGT.balanceOf(user), initialBalance, "Should have received yBGT rewards");
    }

    function testClaimAndStake() public {
        // Push rewards
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 initialStakedBalance = IBearnVault(address(styBGT)).balanceOf(user);
        
        address[] memory vaults = new address[](1);
        vaults[0] = address(bearnVault);

        vm.prank(user);
        claimer.claimAndStake(vaults);

        assertGt(
            IBearnVault(address(styBGT)).balanceOf(user),
            initialStakedBalance,
            "Should have received staked yBGT"
        );
        assertEq(
            yBGT.balanceOf(user),
            0,
            "Should have no loose yBGT"
        );
    }

    function testClaimAndCompound() public {
        // Push rewards
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 initialCompoundedBalance = IBearnVault(address(styBGTCompounder)).balanceOf(user);
        
        address[] memory vaults = new address[](1);
        vaults[0] = address(bearnVault);

        vm.prank(user);
        claimer.claimAndCompound(vaults);

        assertGt(
            IBearnVault(address(styBGTCompounder)).balanceOf(user),
            initialCompoundedBalance,
            "Should have received compounded yBGT"
        );
        assertEq(
            yBGT.balanceOf(user),
            0,
            "Should have no loose yBGT"
        );
    }

    function testAutoClaimSetup() public {
        address[] memory vaults = new address[](1);
        vaults[0] = address(bearnVault);
        bool[] memory autoClaim = new bool[](1);
        autoClaim[0] = true;

        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit AutoClaimSet(user, address(bearnVault), true);
        claimer.setAutoClaim(vaults, autoClaim);

        // Push rewards and trigger auto claim
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 initialBalance = yBGT.balanceOf(user);
        claimer.autoClaim(address(bearnVault));
        
        assertGt(
            yBGT.balanceOf(user),
            initialBalance,
            "Auto claim should have distributed rewards"
        );
    }

    function testAutoClaimAndStakeAll() public {
        address[] memory vaults = new address[](1);
        vaults[0] = address(bearnVault);
        bool[] memory autoClaim = new bool[](1);
        autoClaim[0] = true;

        vm.prank(user);
        claimer.setAutoClaimAndStake(vaults, autoClaim);

        // Push rewards
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 initialStakedBalance = IBearnVault(address(styBGT)).balanceOf(user);
        claimer.autoClaimAndStakeAll();

        assertGt(
            IBearnVault(address(styBGT)).balanceOf(user),
            initialStakedBalance,
            "Auto claim and stake should have increased staked balance"
        );
    }

    function testAutoClaimAndCompoundAll() public {
        address[] memory vaults = new address[](1);
        vaults[0] = address(bearnVault);
        bool[] memory autoClaim = new bool[](1);
        autoClaim[0] = true;

        vm.prank(user);
        claimer.setAutoClaimAndCompound(vaults, autoClaim);

        // Push rewards
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 initialCompoundedBalance = IBearnVault(address(styBGTCompounder)).balanceOf(user);
        claimer.autoClaimAndCompoundAll();

        assertGt(
            IBearnVault(address(styBGTCompounder)).balanceOf(user),
            initialCompoundedBalance,
            "Auto claim and compound should have increased compounded balance"
        );
    }

    function testMultipleVaultsClaim() public {
        MockERC20 mockToken = new MockERC20();
        mockToken.initialize("MOCK", "MOCK", 18);
        deal(address(mockToken), user, 100 ether);
        vm.prank(governance);
        IBeraVault beraVault2 = IBeraVault(factory.createRewardVault(address(mockToken)));
        vm.prank(governance);
        beraVault2.setRewardsDuration(3);

        // Create another vault for testing
        (address compoundingVault2, address bgtEarnerVault2) = bearnVaultFactory.createVaults(address(mockToken));
        
        // Setup deposits in second vault
        vm.startPrank(user);
        mockToken.approve(bgtEarnerVault2, type(uint256).max);
        IBearnVault(bgtEarnerVault2).deposit(1 ether, user);
        IBearnVault(bgtEarnerVault2).setClaimForSelf(address(claimer));
        vm.stopPrank();

        // Push rewards to both vaults
        _pushRewardsAndReport(address(bearnVault), 1 ether);
        // add BGT to bera reward vault
        vm.prank(address(distributor));
        bgt.approve(address(beraVault2), type(uint256).max);
        vm.prank(address(distributor));
        beraVault2.notifyRewardAmount(valData.pubkey, 1 ether);

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 1);

        keeper.report(bgtEarnerVault2);

        address[] memory vaults = new address[](2);
        vaults[0] = address(bearnVault);
        vaults[1] = bgtEarnerVault2;

        uint256 initialBalance = yBGT.balanceOf(user);
        
        vm.prank(user);
        claimer.claim(vaults);

        assertGt(
            yBGT.balanceOf(user) - initialBalance,
            1 ether,
            "Should have received rewards from both vaults"
        );
    }

    function testClaimWithNoRewards() public {
        address[] memory vaults = new address[](1);
        vaults[0] = address(bearnVault);

        uint256 initialBalance = yBGT.balanceOf(user);
        
        vm.prank(user);
        claimer.claim(vaults);

        assertEq(
            yBGT.balanceOf(user),
            initialBalance,
            "Balance should not change when there are no rewards"
        );
    }
}