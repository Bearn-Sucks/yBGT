// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AuctionSwapper, Auction} from "@yearn/tokenized-strategy-periphery/swappers/AuctionSwapper.sol";

import {BearnVault} from "src/BearnVault.sol";

contract BearnBGTEarnerVault is BearnVault {
    using SafeERC20 for IERC20;

    uint256 public lastClaimedBlock;

    /* ========== ERRORS ========== */

    error AuctionNotDeployed();

    /* ========== EVENTS ========== */

    event SentToTreasury(address token, uint256 amount);

    /* ========== MODIFIERS ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        address _asset,
        address _beraVault,
        address _yBGT
    ) BearnVault(_name, _symbol, _asset, _beraVault, _yBGT) {}

    /// @notice Adds yBGT as an instantly released reward
    function _initialize() internal override {
        // using 1 second to signal instant release
        _addReward(address(yBGT), address(this), 1);
    }

    function _claimAndNotify() internal virtual {
        // only run once a block
        if (block.number != lastClaimedBlock) {
            lastClaimedBlock = block.number;

            // This claims the BGT to the Bearn Voter in return for yBGT
            uint256 rewardAmount = yBGT.wrap(address(asset));

            if (rewardAmount > 0) {
                // notify the newly received yBGT
                _notifyRewardAmount(address(yBGT), rewardAmount);
            }
        }
    }

    /* ========== OVERRIDES ========== */

    function _updateReward(address _account) internal override {
        // claim and notify first before updating user rewards
        // this will run on deposits, withdrawals, transfers, and getRewards
        if (_account != address(0)) {
            _claimAndNotify();
        }

        super._updateReward(_account);
    }

    function _harvestAndReport()
        internal
        virtual
        override
        returns (uint256 _totalAssets)
    {
        _claimAndNotify();

        // stake any excess asset
        uint256 excessAmount = asset.balanceOf(address(this));
        if (excessAmount > 0) {
            beraVault.stake(excessAmount);
        }

        // report total assets
        _totalAssets = beraVault.balanceOf(address(this));
    }
}
