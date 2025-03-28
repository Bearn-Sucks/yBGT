// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {BearnBGTEarnerVaultTest} from "test/BearnBGTEarnerVault.t.sol";
import {IStakedBearnBGTCompounder} from "src/interfaces/IStakedBearnBGTCompounder.sol";

contract BearnCompoundingVaultTest is BearnBGTEarnerVaultTest {
    /// @dev A function invoked before each test case is run.
    function setUp() public virtual override {
        super.setUp();
    }

    function test_deposit() public override {
        vm.startPrank(user);
        uint256 balance = bearnCompoundingVault.deposit(1 ether, user);

        require(
            bearnCompoundingVault.balanceOf(user) == balance,
            "vault deposit not working"
        );
    }

    function test_withdraw() public override {
        vm.startPrank(user);

        uint256 balanceBefore = wbera.balanceOf(user);

        bearnCompoundingVault.deposit(1 ether, user);
        bearnCompoundingVault.withdraw(1 ether, user, user);

        uint256 balanceAfter = wbera.balanceOf(user);
        require(balanceBefore == balanceAfter, "vault withdraw not working");
    }

    function test_report() public override {
        vm.prank(user);
        bearnCompoundingVault.deposit(1 ether, user);

        uint256 balanceBefore = yBGT.balanceOf(
            address(bearnCompoundingVaultAuction)
        );
        console.log(
            "bearnCompoundingVaultAuction yBGT balance before",
            balanceBefore
        );

        _pushRewardsAndReport(address(bearnCompoundingVault), 1 ether);

        uint256 balanceAfter = yBGT.balanceOf(
            address(bearnCompoundingVaultAuction)
        );
        console.log(
            "bearnCompoundingVaultAuction yBGT balance after",
            balanceAfter
        );
        assertApproxEqAbs(1 ether, balanceAfter - balanceBefore, 0.1 gwei);
    }

    function test_auction() public {
        vm.prank(user);
        bearnCompoundingVault.deposit(1 ether, user);

        uint256 balanceBefore = wbera.balanceOf(address(bearnCompoundingVault));
        console.log("balance before auction", balanceBefore);

        _holdAuction();

        uint256 balanceAfter = wbera.balanceOf(address(bearnCompoundingVault));
        console.log("balance after auction", balanceAfter);

        assertGt(balanceAfter, balanceBefore);
    }

    function test_getReward() public override {
        vm.prank(user);
        bearnCompoundingVault.deposit(1 ether, user);

        uint256 userBalanceBefore = bearnCompoundingVault.previewRedeem(
            bearnCompoundingVault.balanceOf(user)
        );
        console.log("user LP balance before", userBalanceBefore);

        // hold auction, notify, then wait for a week to get all the rewards
        uint256 addedAmount = _holdAuction();
        _pushRewardsAndReport(address(bearnCompoundingVault), 1 ether);
        vm.warp(block.timestamp + 86400 * 10);

        vm.prank(user);
        bearnVault.getReward();
        uint256 userBalanceAfter = bearnCompoundingVault.previewRedeem(
            bearnCompoundingVault.balanceOf(user)
        );
        console.log("user LP balance after", userBalanceAfter);

        console.log(
            "treasury LP balance after",
            bearnCompoundingVault.previewRedeem(
                bearnCompoundingVault.balanceOf(address(treasury))
            )
        );
        console.log(
            "protocol LP balance after",
            bearnCompoundingVault.previewRedeem(
                bearnCompoundingVault.balanceOf(protocolFeeRecipient)
            )
        );

        assertApproxEqAbs(
            (userBalanceAfter - userBalanceBefore) +
                bearnCompoundingVault.previewRedeem(
                    bearnCompoundingVault.balanceOf(address(treasury))
                ) +
                bearnCompoundingVault.previewRedeem(
                    bearnCompoundingVault.balanceOf(protocolFeeRecipient)
                ),
            addedAmount,
            0.1 gwei
        );

        assertGt(userBalanceAfter, userBalanceBefore);
    }

    function _holdAuction() internal returns (uint256) {
        _pushRewardsAndReport(address(bearnCompoundingVault), 1 ether);

        // Wait some time for price to drop a bit
        vm.warp(block.timestamp + 20 hours);

        // Prepare auction taker
        address auctionTaker = makeAddr("auctionTaker");
        vm.startPrank(auctionTaker);
        vm.deal(auctionTaker, 1000 ether);
        wbera.deposit{value: 100 ether}();
        wbera.approve(address(bearnCompoundingVaultAuction), type(uint256).max);

        uint256 amount = bearnCompoundingVaultAuction.getAmountNeeded(
            address(yBGT),
            yBGT.balanceOf(address(bearnCompoundingVaultAuction))
        );

        // Take Auction
        bearnCompoundingVaultAuction.take(address(yBGT));

        // Speed up time for rewards to be distributed
        vm.warp(block.timestamp + 86400 * 6);

        vm.stopPrank();

        return amount;
    }

    function testReportHandlesHoneyAndOtherRewards() public {
        MockERC20 otherReward = new MockERC20();
        otherReward.initialize("OTHER", "OTHER", 18);

        deal(address(yBGT), address(user), 10000 ether);
        vm.startPrank(user);
        yBGT.approve(address(styBGT), type(uint256).max);
        IBearnVault(address(styBGT)).deposit(10000 ether, user);
        IBearnVault(address(styBGT)).approve(address(styBGTCompounder), type(uint256).max);
        IBearnVault(address(styBGTCompounder)).deposit(10000 ether, user);
        vm.stopPrank();

        // Add other reward to styBGT
        vm.startPrank(bearnManager);
        styBGT.addReward(address(otherReward), address(address(bearnManager)), 1 days);
        styBGTCompounder.addReward(address(otherReward), address(styBGTCompounderClaimer), 1 days);

        // Grant keeper role to test address
        authorizer.grantRole(styBGTCompounderClaimer.KEEPER_ROLE(), address(this));
        vm.stopPrank();

        // Setup initial state
        uint256 honeyAmount = 1000e18;
        uint256 otherRewardAmount = 500e18;

        // Mint and transfer rewards to styBGT (simulating rewards accumulation)
        deal(address(honey), address(bearnManager), honeyAmount);
        deal(address(otherReward), address(bearnManager), otherRewardAmount);

        vm.startPrank(address(bearnManager));
        honey.approve(address(styBGT), honeyAmount);
        otherReward.approve(address(styBGT), otherRewardAmount);
        styBGT.notifyRewardAmount(address(honey), honeyAmount);
        styBGT.notifyRewardAmount(address(otherReward), otherRewardAmount);
        vm.stopPrank();

        skip(1 days);

        // Store initial balances
        uint256 initialHoneyBalance = honey.balanceOf(address(styBGTCompounderClaimer));
        uint256 initialOtherRewardBalance = otherReward.balanceOf(address(styBGTCompounderClaimer));
        bool initialAuctionActive = styBGTCompounderClaimer.auction().isActive(address(honey));

        // Call report
        styBGTCompounderClaimer.report();

        skip(1 hours);

        // Verify honey was sent to auction
        assertTrue(
            styBGTCompounderClaimer.auction().isActive(address(honey)),
            "Honey auction should be active"
        );
        assertGt(
            honey.balanceOf(address(styBGTCompounderClaimer.auction())),
            0,
            "All honey should be in auction"
        );

        // Verify other reward was notified to compounder
        assertGt(
            otherReward.balanceOf(address(styBGTCompounder)),
            0,
            "Other reward should be transferred to compounder"
        );

        // Verify rewards are properly tracked in compounder
        uint256 notifiedReward = IStakedBearnBGTCompounder(address(styBGTCompounder)).rewardData(address(otherReward)).rewardRate;
        assertTrue(notifiedReward > 0, "Reward rate should be set");
    }

    function testReportDoesNotKickAuctionIfAlreadyActive() public {
        MockERC20 otherReward = new MockERC20();
        otherReward.initialize("OTHER", "OTHER", 18);

        deal(address(yBGT), address(user), 10000 ether);
        vm.startPrank(user);
        yBGT.approve(address(styBGT), type(uint256).max);
        IBearnVault(address(styBGT)).deposit(10000 ether, user);
        IBearnVault(address(styBGT)).approve(address(styBGTCompounder), type(uint256).max);
        IBearnVault(address(styBGTCompounder)).deposit(10000 ether, user);
        vm.stopPrank();

        // Add other reward to styBGT
        vm.startPrank(bearnManager);
        styBGT.addReward(address(otherReward), address(styBGTCompounderClaimer), 1 days);
        styBGTCompounder.addReward(address(otherReward), address(styBGTCompounderClaimer), 1 days);

        // Grant keeper role to test address
        authorizer.grantRole(styBGTCompounderClaimer.KEEPER_ROLE(), address(this));
        vm.stopPrank();

        // Setup initial state with honey rewards
        uint256 honeyAmount = 1000e18;
        deal(address(honey), address(bearnManager), honeyAmount);

        vm.startPrank(address(bearnManager));
        honey.approve(address(styBGT), honeyAmount);
        styBGT.notifyRewardAmount(address(honey), honeyAmount);
        vm.stopPrank();

        skip(1 hours);

        // First report to kick off auction
        styBGTCompounderClaimer.report();
        assertTrue(
            styBGTCompounderClaimer.auction().isActive(address(honey)),
            "First auction should be active"
        );

        // Add more honey rewards
        deal(address(honey), address(bearnManager), honeyAmount);
        vm.startPrank(address(bearnManager));
        honey.approve(address(styBGT), honeyAmount);
        styBGT.notifyRewardAmount(address(honey), honeyAmount);
        vm.stopPrank();

        // Second report
        styBGTCompounderClaimer.report();

        // Verify new honey is held until current auction completes
        assertGt(
            honey.balanceOf(address(styBGTCompounderClaimer)),
            0,
            "New honey should be held in claimer"
        );
    }
}
