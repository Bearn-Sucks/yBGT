// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AuctionSwapper, Auction} from "@yearn/tokenized-strategy-periphery/swappers/AuctionSwapper.sol";

import {BearnVault} from "src/BearnVault.sol";

contract BearnCompoundingVault is BearnVault, AuctionSwapper {
    // @TODO: Fork AuctionSwapper and AuctionFactory to resolve CoW and Yearn addresses that are hardcoded
    using SafeERC20 for IERC20;

    /* ========== ERRORS ========== */

    error AuctionNotDeployed();

    /* ========== EVENTS ========== */

    /* ========== MODIFIERS ========== */

    constructor(
        string memory _name,
        address _asset,
        address _beraVault,
        address _yBGT
    ) BearnVault(_name, _asset, _beraVault, _yBGT) {
        // Auction length should be 6 days, leaves 1 days for management to change settings if needed
        _enableAuction(address(yBGT), address(asset), 518400, 1e6);
    }

    /// @notice Override initialization since compounding vaults don't have yBGT as a reward
    function _initialize() internal override {}

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        // This claims the BGT to the Bearn Voter in return for yBGT
        yBGT.wrap(address(asset));

        _kickAuction(address(yBGT));

        // stake any excess asset (from auctions)
        uint256 excessAmount = asset.balanceOf(address(this));
        if (excessAmount > 0) {
            beraVault.stake(excessAmount);
        }

        // report total assets
        _totalAssets = beraVault.balanceOf(address(this));
    }

    /* ========== MANAGEMENT ACTIONS ========== */
    function enableAuction() external onlyManagement {
        Auction(auction).enable(address(yBGT));
    }

    function disableAuction() external onlyManagement {
        _disableAuction(address(yBGT));
    }

    function setStartingPrice(uint256 _startingPrice) external onlyManagement {
        Auction(auction).setStartingPrice(_startingPrice);
    }

    function sweepFromAuction(address _token) external onlyManagement {
        Auction(auction).sweep(_token);
    }
}
