// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {AuctionSwapper, Auction} from "@yearn/tokenized-strategy-periphery/swappers/AuctionSwapper.sol";

import {BearnVault} from "src/BearnVault.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BearnCompoundingVault is BearnVault, AuctionSwapper {
    /* ========== ERRORS ========== */

    error AuctionNotDeployed();

    /* ========== EVENTS ========== */

    /* ========== MODIFIERS ========== */
    modifier hasAuction() {
        _hasAuction();
        _;
    }

    function _hasAuction() internal view {
        require(auction != address(0), AuctionNotDeployed());
    }

    constructor(
        string memory _name,
        address _asset,
        address _beraVault,
        address _yBGT
    ) BearnVault(_name, _asset, _beraVault, _yBGT) {}

    /// @notice Override initialization since compounding vaults don't have yBGT as a reward
    function _initialize() internal override {}

    function _harvestAndReport()
        internal
        override(BearnVault)
        returns (uint256 _totalAssets)
    {
        // This claims the BGT to the Bearn Voter in return for yBGT
        yBGT.wrap(address(asset));

        // Auction length should be 6 days, leaves 1 days for management to change settings if needed
        _enableAuction(address(yBGT), address(asset), 518400, 1e6);
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
    function enableAuction() external onlyManagement hasAuction {
        Auction(auction).enable(address(yBGT));
    }

    function disableAuction() external onlyManagement hasAuction {
        _disableAuction(address(yBGT));
    }

    function setStartingPrice(
        uint256 _startingPrice
    ) external onlyManagement hasAuction {
        Auction(auction).setStartingPrice(_startingPrice);
    }

    function sweepFromAuction(
        address _token
    ) external onlyManagement hasAuction {
        Auction(auction).sweep(_token);
    }
}
