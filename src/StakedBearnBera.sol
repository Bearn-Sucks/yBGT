// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "@yearn/vaults-v3/interfaces/IVault.sol";

import {TokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/TokenizedStaker.sol";
import {TokenizedStrategy} from "@yearn/tokenized-strategy/TokenizedStrategy.sol";

/// @title Staked Bearn Bera
/// @author bearn.sucks
/// @notice A contract for users to stake and get rewards from berachin for their yBERA
contract StakedBearnBera is TokenizedStaker {
    using SafeERC20 for IERC20;

    IVault public immutable yBERA;
    IERC20 public immutable wbera;

    constructor(
        address _yBERA
    ) TokenizedStaker(_yBERA, "Staked Bearn Bera") {
        yBERA = IVault(_yBERA);
        wbera = IERC20(yBERA.asset());
    }

    function symbol() public view returns (string memory) {
        return "styBERA";
    }

    function _deployFunds(uint256 amount) internal override {}

    function _freeFunds(uint256 amount) internal override {}

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        uint256 wberaBalance = wbera.balanceOf(address(this));

        if (wberaBalance > 0) {
            wbera.forceApprove(address(yBERA), wberaBalance);
            yBERA.deposit(wberaBalance, address(this));
        }

        // report total assets
        _totalAssets = yBERA.balanceOf(address(this));
    }
}
