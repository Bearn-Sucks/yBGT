// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {TokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/TokenizedStaker.sol";
import {TokenizedStrategy} from "@yearn/tokenized-strategy/TokenizedStrategy.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";
import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BearnVault is TokenizedStaker {
    // @TODO: fork TokenizedStrategy to replace hardcoded address for getting protocol fees

    IBeraVault public immutable beraVault;
    IBearnVoter public immutable bearnVoter;
    IBearnBGT public immutable yBGT;

    constructor(
        string memory _name,
        address _asset,
        address _beraVault,
        address _yBGT
    ) TokenizedStaker(_asset, _name) {
        beraVault = IBeraVault(_beraVault);
        yBGT = IBearnBGT(_yBGT);

        // set up approvals
        IERC20(_asset).approve(address(beraVault), type(uint256).max);

        // call setOperator so the BGT can be claimed to Bearn Voter
        IBeraVault(_beraVault).setOperator(_yBGT);

        //Overrideable initialization since this part will be different for Compounding Vaults
        _initialize();
    }

    /// @notice Overrideable initialization since this part will be different for Compounding Vaults
    function _initialize() internal virtual {
        _addReward(address(yBGT), address(this), 86400 * 7);
    }

    function _deployFunds(uint256 amount) internal override {
        beraVault.stake(amount);
    }

    function _freeFunds(uint256 amount) internal override {
        beraVault.withdraw(amount);
    }

    function _harvestAndReport()
        internal
        virtual
        override
        returns (uint256 _totalAssets)
    {
        // This claims the BGT to the Bearn Voter in return for yBGT
        uint256 rewardAmount = yBGT.wrap(address(asset));

        // notify the newly received yBGT
        _notifyRewardAmount(address(yBGT), rewardAmount);

        // stake any excess asset
        uint256 excessAmount = asset.balanceOf(address(this));
        if (excessAmount > 0) {
            beraVault.stake(excessAmount);
        }

        // report total assets
        _totalAssets = beraVault.balanceOf(address(this));
    }
}
