// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ITokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/ITokenizedStaker.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title yBERA Zapper
/// @author bearn.sucks
/// @notice Zaps WBERA into staked yBERA and vice versa
contract YBeraZapper {
    ITokenizedStaker public constant styBera =
        ITokenizedStaker(0xCD0A794A2FfF32e21Dc4fE3081909Ad7e4B55a35);
    ITokenizedStaker public constant yBera =
        ITokenizedStaker(0x982940eBfC5caa2F5b5a82AAc2Dfa99F18BB7dA4);
    IERC20 public constant wbera =
        IERC20(0x6969696969696969696969696969696969696969);

    function nativeZapIn() public payable returns (uint256 shares) {
        (bool success, ) = address(wbera).call{value: msg.value}("");
        require(success, "WBERA deposit failed");

        return _zapIn(msg.value);
    }

    function zapIn(uint256 assets) external returns (uint256 shares) {
        wbera.transferFrom(msg.sender, address(this), assets);

        return _zapIn(assets);
    }

    function _zapIn(uint256 assets) internal returns (uint256 shares) {
        wbera.approve(address(yBera), assets);

        uint256 yBeraShares = yBera.deposit(assets, address(this));

        yBera.approve(address(styBera), yBeraShares);

        return styBera.deposit(yBeraShares, msg.sender);
    }

    function zapOut(uint256 shares) external returns (uint256 assets) {
        uint256 yBeraShares = styBera.redeem(shares, address(this), msg.sender);

        return yBera.redeem(yBeraShares, msg.sender, address(this));
    }

    receive() external payable {
        nativeZapIn();
    }
}
