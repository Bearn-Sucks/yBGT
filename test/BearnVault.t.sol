// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import "forge-std/Test.sol";

import {BearnBaseHelper} from "test/BearnBaseHelper.t.sol";

contract BearnVaultTest is BearnBaseHelper {
    /// @dev A function invoked before each test case is run.
    function setUp() public virtual override {
        super.setUp();

        // set up user balances
        vm.startPrank(user);
        vm.deal(user, 100 ether);
        wbera.deposit{value: 10 ether}();
        // set up approvals
        wbera.approve(address(bearnVault), type(uint256).max);

        vm.stopPrank();
    }

    function test_deposit() public {
        vm.startPrank(user);
        uint256 balance = bearnVault.deposit(1 ether, user);

        require(
            bearnVault.balanceOf(user) == balance,
            "vault deposit not working"
        );
    }

    function test_withdraw() public {
        vm.startPrank(user);

        uint256 balanceBefore = wbera.balanceOf(user);

        bearnVault.deposit(1 ether, user);
        bearnVault.withdraw(1 ether, user, user);

        uint256 balanceAfter = wbera.balanceOf(user);
        require(balanceBefore == balanceAfter, "vault withdraw not working");
    }

    function test_report() public {
        _addRewardsAndReport();
    }

    function test_getReward() public {
        _addRewardsAndReport();

        assertEq(0, yBGT.balanceOf(user));
        console.log("user yBGT balance before", yBGT.balanceOf(user));

        vm.prank(user);
        bearnVault.getReward();

        console.log("user yBGT balance after", yBGT.balanceOf(user));

        assertApproxEqAbs(1 ether, yBGT.balanceOf(user), 0.1 gwei);
    }

    function _addRewardsAndReport() internal {
        vm.prank(user);
        bearnVault.deposit(1 ether, user);

        assertEq(0, yBGT.balanceOf(address(bearnVault)));

        // add BGT to bera reward vault
        vm.prank(address(distributor));
        bgt.approve(address(beraVault), type(uint256).max);
        vm.prank(address(distributor));
        beraVault.notifyRewardAmount(valData.pubkey, 1 ether);

        vm.warp(block.timestamp + 3);

        vm.prank(bearnManager);
        bearnVaultFactory.report(address(bearnVault));

        assertApproxEqAbs(1 ether, yBGT.balanceOf(address(bearnVault)), 1);

        vm.warp(block.timestamp + 86400 * 8);
    }
}
