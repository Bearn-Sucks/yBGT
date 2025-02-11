// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AuctionSwapper, Auction} from "@yearn/tokenized-strategy-periphery/swappers/AuctionSwapper.sol";

import {BearnVault} from "src/BearnVault.sol";

contract BearnBGTEarnerVault is BearnVault {
    using SafeERC20 for IERC20;

    /* ========== ERRORS ========== */

    error AuctionNotDeployed();

    /* ========== EVENTS ========== */

    event SentToTreasury(address token, uint256 amount);

    /* ========== MODIFIERS ========== */

    constructor(
        string memory _name,
        address _asset,
        address _beraVault,
        address _yBGT
    ) BearnVault(_name, _asset, _beraVault, _yBGT) {}

    /// @notice Adds yBGT as an instantly released reward
    function _initialize() internal override {
        // using 1 second to signal instant release
        _addReward(address(yBGT), address(this), 1);
    }

    function _claimAndNotify() internal virtual {
        // This claims the BGT to the Bearn Voter in return for yBGT
        uint256 rewardAmount = yBGT.wrap(address(asset));

        if (rewardAmount > 0) {
            // notify the newly received yBGT
            _notifyRewardAmount(address(yBGT), rewardAmount);
        }
    }

    /* ========== OVERRIDES ========== */

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

    function _preDepositHook(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal virtual override {
        // Claim before deposits, withdraws, and transfers
        _claimAndNotify();
        super._preDepositHook(assets, shares, receiver);
    }

    function _preWithdrawHook(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss
    ) internal virtual override {
        // Claim before deposits, withdraws, and transfers
        _claimAndNotify();
        super._preWithdrawHook(assets, shares, receiver, owner, maxLoss);
    }

    function _preTransferHook(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Claim before deposits, withdraws, and transfers
        _claimAndNotify();
        super._preTransferHook(from, to, amount);
    }
}
