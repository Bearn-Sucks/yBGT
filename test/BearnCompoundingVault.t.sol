// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import "forge-std/Test.sol";

import {BearnBGTEarnerVaultTest} from "test/BearnBGTEarnerVault.t.sol";

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
            "management LP balance after",
            bearnCompoundingVault.previewRedeem(
                bearnCompoundingVault.balanceOf(address(bearnVaultManager))
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
                    bearnCompoundingVault.balanceOf(address(bearnVaultManager))
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
        vm.warp(block.timestamp + 86400 * 1);

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

        bearnCompoundingVaultAuction.take(address(yBGT));

        vm.warp(block.timestamp + 86400 * 6);

        vm.stopPrank();

        return amount;
    }
}
