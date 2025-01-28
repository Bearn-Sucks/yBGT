// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import "forge-std/Test.sol";

import {BearnVaultTest} from "test/BearnVault.t.sol";

contract BearnCompoundingVaultTest is BearnVaultTest {
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
        _pushRewardsAndReport(address(bearnCompoundingVault), 1 ether);
    }

    function test_getReward() public override {
        // // Push rewards to Bearn Vault and wait for a week
        // _pushRewardsAndReport(address(bearnVault), 1 ether);
        // vm.warp(block.timestamp + 86400 * 7);
        // uint256 balanceBefore = yBGT.balanceOf(user);
        // console.log("user yBGT balance before", balanceBefore);
        // vm.prank(user);
        // bearnVault.getReward();
        // uint256 balanceAfter = yBGT.balanceOf(user);
        // console.log("user yBGT balance after", balanceAfter);
        // assertApproxEqAbs(1 ether, balanceAfter - balanceBefore, 0.1 gwei);
    }
}
