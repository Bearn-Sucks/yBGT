// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ITokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/ITokenizedStaker.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title yHoney Zapper
/// @author bearn.sucks
/// @notice Zaps Honey into staked yHoney and vice versa
contract YHoneyZapper {
    ITokenizedStaker public constant styHoney =
        ITokenizedStaker(0x99d6A0FB9420F3995fD07dCc36AC827a8E146cf9);
    ITokenizedStaker public constant yHoney =
        ITokenizedStaker(0xC82971BcFF09171e16Ac08AEE9f4EA3fB16C3BDC);
    IERC20 public constant honey =
        IERC20(0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce);

    function zapIn(uint256 assets) external returns (uint256 shares) {
        honey.transferFrom(msg.sender, address(this), assets);

        return _zapIn(assets);
    }

    function _zapIn(uint256 assets) internal returns (uint256 shares) {
        honey.approve(address(yHoney), assets);

        uint256 yHoneyShares = yHoney.deposit(assets, address(this));

        yHoney.approve(address(styHoney), yHoneyShares);

        return styHoney.deposit(yHoneyShares, msg.sender);
    }

    function zapOut(uint256 shares) external returns (uint256 assets) {
        uint256 yHoneyShares = styHoney.redeem(shares, address(this), msg.sender);

        return yHoney.redeem(yHoneyShares, msg.sender, address(this));
    }
}