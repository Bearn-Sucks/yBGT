// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/TokenizedStaker.sol";
import {TokenizedStrategy} from "@yearn/tokenized-strategy/TokenizedStrategy.sol";
import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";
import {AuctionFactory} from "@yearn/tokenized-strategy-periphery/Auctions/AuctionFactory.sol";

import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";
import {IBearnVoterManager} from "src/interfaces/IBearnVoterManager.sol";
import {IBearnVaultManager} from "src/interfaces/IBearnVaultManager.sol";
import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";

/// @title StakedBearnBGT
/// @author bearn.sucks
/// @notice A contract for users to stake and get rewards from berachin for their yBGT
contract StakedBearnBGT is TokenizedStaker {
    using SafeERC20 for IERC20;

    IBearnVoter public immutable bearnVoter;
    IBearnBGT public immutable yBGT;
    IERC20 public immutable honey;
    IBearnVaultManager public immutable bearnVaultManager;

    constructor(
        address _bearnVoter,
        address _bearnVaultManager,
        address _yBGT,
        address _honey
    ) TokenizedStaker(_yBGT, "styBGT") {
        yBGT = IBearnBGT(_yBGT);
        honey = IERC20(_honey);
        bearnVoter = IBearnVoter(_bearnVoter);
        bearnVaultManager = IBearnVaultManager(_bearnVaultManager);
    }

    function _deployFunds(uint256 amount) internal override {}

    function _freeFunds(uint256 amount) internal override {}

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        // Fetch voterManager as it can change
        IBearnVoterManager voterManager = IBearnVoterManager(
            bearnVoter.voterManager()
        );

        // Call getReward() to transfer honey to this address
        uint256 honeyBefore = honey.balanceOf(address(this));
        voterManager.getReward();
        uint256 rewardAmount = honey.balanceOf(address(this)) - honeyBefore;

        // Notify rewards if needed
        if (rewardAmount > 0) {
            // notify the newly received honey
            _notifyRewardAmount(address(honey), rewardAmount);
        }

        // report total assets
        _totalAssets = yBGT.balanceOf(address(this));
    }
}
