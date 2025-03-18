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

    uint256 public lastClaimedBlock;

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
        _addReward(_honey, address(this), 1);
    }

    function _deployFunds(uint256 amount) internal override {}

    function _freeFunds(uint256 amount) internal override {}

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        _claimAndNotify();

        // report total assets
        _totalAssets = yBGT.balanceOf(address(this));
    }

    /* ========== OVERRIDES ========== */

    function _updateReward(address _account) internal override {
        // claim and notify first before updating user rewards
        // this will run on deposits, withdrawals, transfers, and getRewards
        if (_account != address(0)) {
            _claimAndNotify(); // this won't cause infinite loops because we only run _claimAndNotify once per block
        }

        super._updateReward(_account);
    }

    function _claimAndNotify() internal {
        // only run once a block
        if (block.number != lastClaimedBlock) {
            lastClaimedBlock = block.number; // this is safe since rewards can't come in in the middle of a block

            // Fetch voterManager as it can change
            IBearnVoterManager voterManager = IBearnVoterManager(
                bearnVoter.voterManager()
            );

            // Call getReward() to transfer honey to this address
            uint256 rewardAmount = voterManager.getReward();

            // transfer fees if needed
            uint256 feeBps = TokenizedStrategy.performanceFee();
            uint256 fees = (rewardAmount * feeBps) / 10_000;
            if (fees > 0) {
                rewardAmount -= fees;
                honey.safeTransfer(
                    TokenizedStrategy.performanceFeeRecipient(),
                    fees
                );
            }

            // Notify rewards if needed
            if (rewardAmount > 0) {
                // notify the newly received honey
                _notifyRewardAmount(address(honey), rewardAmount);
            }
        }
    }
}
