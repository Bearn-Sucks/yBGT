// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "@yearn/vaults-v3/interfaces/IVault.sol";

import {TokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/TokenizedStaker.sol";
import {TokenizedStrategy} from "@yearn/tokenized-strategy/TokenizedStrategy.sol";

/// @title Staked Bearn Honey
/// @author bearn.sucks
/// @notice A contract for users to stake and get the yield from their yHONEY
contract StakedBearnHoney is TokenizedStaker {
    using SafeERC20 for IERC20;

    IVault public immutable yHONEY;
    IERC20 public immutable HONEY;

    constructor(
        address _yHONEY
    ) TokenizedStaker(_yHONEY, "Staked Bearn Honey") {
        yHONEY = IVault(_yHONEY);
        HONEY = IERC20(yHONEY.asset());
    }

    function symbol() public view returns (string memory) {
        return "styHONEY";
    }

    function _deployFunds(uint256 amount) internal override {}

    function _freeFunds(uint256 amount) internal override {}

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        uint256 honeyBalance = HONEY.balanceOf(address(this));

        if (honeyBalance > 0) {
            HONEY.forceApprove(address(yHONEY), honeyBalance);
            yHONEY.deposit(honeyBalance, address(this));
        }

        // report total assets
        _totalAssets = yHONEY.balanceOf(address(this));
    }
}
