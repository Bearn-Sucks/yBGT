// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import "forge-std/Test.sol";

import {BearnBaseHelper} from "test/BearnBaseHelper.t.sol";

contract BearnVaultTest is BearnBaseHelper {
    /// @dev A function invoked before each test case is run.
    function setUp() public virtual override {
        super.setUp();
    }

    function test_deposit() public virtual {
        vm.startPrank(user);
        uint256 balance = bearnVault.deposit(1 ether, user);

        require(
            bearnVault.balanceOf(user) == balance,
            "vault deposit not working"
        );
    }

    function test_withdraw() public virtual {
        vm.startPrank(user);

        uint256 balanceBefore = wbera.balanceOf(user);

        bearnVault.deposit(1 ether, user);
        bearnVault.withdraw(1 ether, user, user);

        uint256 balanceAfter = wbera.balanceOf(user);
        require(balanceBefore == balanceAfter, "vault withdraw not working");
    }

    function test_report() public virtual {
        uint256 balanceBefore = yBGT.balanceOf(address(bearnVault));
        console.log("bearnVault yBGT balance before", balanceBefore);

        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 balanceAfter = yBGT.balanceOf(address(bearnVault));
        console.log("bearnVault yBGT balance after", balanceAfter);
        assertApproxEqAbs(1 ether, balanceAfter - balanceBefore, 0.1 gwei);
    }

    function test_getReward() public virtual {
        // Push rewards to Bearn Vault and wait for a week
        _pushRewardsAndReport(address(bearnVault), 1 ether);
        vm.warp(block.timestamp + 86400 * 7);

        uint256 balanceBefore = yBGT.balanceOf(user);

        console.log("user yBGT balance before", balanceBefore);

        vm.prank(user);
        bearnVault.getReward();

        uint256 balanceAfter = yBGT.balanceOf(user);

        console.log("user yBGT balance after", balanceAfter);

        assertApproxEqAbs(1 ether, balanceAfter - balanceBefore, 0.1 gwei);
    }
}
