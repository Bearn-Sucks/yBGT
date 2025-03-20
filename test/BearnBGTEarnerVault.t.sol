// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {BearnBaseHelper} from "test/BearnBaseHelper.t.sol";

contract BearnBGTEarnerVaultTest is BearnBaseHelper {
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
        vm.prank(user);
        bearnVault.deposit(1 ether, user);

        uint256 balanceBefore = yBGT.balanceOf(address(bearnVault));
        console.log("bearnVault yBGT balance before", balanceBefore);

        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 balanceAfter = yBGT.balanceOf(address(bearnVault));
        console.log("bearnVault yBGT balance after", balanceAfter);
        assertApproxEqAbs(balanceAfter - balanceBefore, 1 ether, 0.1 gwei);
    }

    function test_getReward() public virtual {
        vm.prank(user);
        bearnVault.deposit(1 ether, user);

        // Push rewards to Bearn Vault, rewards should be released instantly
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 balanceBefore = yBGT.balanceOf(user);

        console.log("user yBGT balance before", balanceBefore);

        vm.prank(user);
        bearnVault.getReward();

        uint256 balanceAfter = yBGT.balanceOf(user);

        console.log("user yBGT balance after", balanceAfter);

        assertApproxEqAbs(balanceAfter - balanceBefore, 1 ether, 0.1 gwei);
    }

    function test_getReward_Multiple_Users() public virtual {
        vm.prank(user);
        bearnVault.deposit(1 ether, user);
        vm.prank(user2);
        bearnVault.deposit(1 ether, user2);

        // Push rewards to Bearn Vault
        _pushRewardsAndReport(address(bearnVault), 1 ether);

        uint256 balanceBefore = yBGT.balanceOf(user);
        uint256 balanceBefore2 = yBGT.balanceOf(user2);

        console.log("user yBGT balance before", balanceBefore);
        console.log("user2 yBGT balance before", balanceBefore2);

        // get user's rewards
        vm.prank(user);
        bearnVault.getReward();

        // try again to see if therea are bugs
        vm.prank(user);
        bearnVault.getReward();

        // get user2's rewards
        vm.prank(user2);
        bearnVault.getReward();

        uint256 balanceAfter = yBGT.balanceOf(user);
        uint256 balanceAfter2 = yBGT.balanceOf(user2);

        console.log("user yBGT balance after", balanceAfter);
        console.log("user2 yBGT balance after", balanceAfter2);

        assertApproxEqAbs(
            balanceAfter - balanceBefore,
            0.5 ether,
            0.1 gwei,
            "user1 wrong"
        );
        assertApproxEqAbs(
            balanceAfter2 - balanceBefore2,
            0.5 ether,
            0.1 gwei,
            "user2 wrong"
        );
    }

    function test_anti_whale_jit() public virtual {
        // deposit as user
        vm.prank(user);
        bearnVault.deposit(1 ether, user);

        // add BGT to bera reward vault
        // but don't push rewards to Bearn Vault
        vm.prank(address(distributor));
        bgt.approve(address(beraVault), type(uint256).max);
        vm.prank(address(distributor));
        beraVault.notifyRewardAmount(valData.pubkey, 1 ether);

        vm.warp(block.timestamp + 3);
        vm.roll(block.number + 1);

        uint256 balanceBefore = yBGT.balanceOf(user);
        uint256 balanceBefore2 = yBGT.balanceOf(user2);

        console.log("user yBGT balance before", balanceBefore);
        console.log("user2 yBGT balance before", balanceBefore2);

        // deposit as whale, trying to get rewards JIT, shouldn't get anything
        vm.prank(user2);
        bearnVault.deposit(1 ether, user2);
        vm.prank(user2);
        bearnVault.getReward();

        vm.warp(block.timestamp + 86400);
        vm.roll(block.number + 1);

        // get user's rewards
        vm.prank(user);
        bearnVault.getReward();

        uint256 balanceAfter = yBGT.balanceOf(user);
        uint256 balanceAfter2 = yBGT.balanceOf(user2);

        console.log("user yBGT balance after", balanceAfter);
        console.log("user2 yBGT balance after", balanceAfter2);

        // user should still be getting all the rewards, and 0 to the whale
        assertApproxEqAbs(
            balanceAfter - balanceBefore,
            1 ether,
            0.1 gwei,
            "user didn't get rewards"
        );
        assertApproxEqAbs(
            balanceAfter2 - balanceBefore2,
            0 ether,
            0.1 gwei,
            "whale got rewards"
        );
    }
}
