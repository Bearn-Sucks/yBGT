// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AuctionSwapper, Auction} from "@yearn/tokenized-strategy-periphery/swappers/AuctionSwapper.sol";

import {IBearnAuctionFactory} from "src/interfaces/IBearnAuctionFactory.sol";

import {BearnVault} from "src/BearnVault.sol";

contract BearnCompoundingVault is BearnVault {
    using SafeERC20 for IERC20;

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
        override
        returns (uint256 _totalAssets)
    {
        // This claims the BGT to the Bearn Voter in return for yBGT
        yBGT.wrap(address(asset));

        _kickAuction();

        // stake any excess asset (from auctions)
        uint256 excessAmount = asset.balanceOf(address(this));
        if (excessAmount > 0) {
            beraVault.stake(excessAmount);
        }

        // report total assets
        _totalAssets = beraVault.balanceOf(address(this));
    }

    /// @dev Kick an auction
    function _kickAuction() internal {
        IBearnAuctionFactory auctionFactory = IBearnAuctionFactory(
            bearnVaultFactory.bearnAuctionFactory()
        );

        uint256 _balance = IERC20(yBGT).balanceOf(address(this));
        IERC20(yBGT).safeApprove(address(auctionFactory), _balance);

        auctionFactory.kickAuction(address(asset), _balance);
    }

    function auction() external view returns (address) {
        IBearnAuctionFactory auctionFactory = IBearnAuctionFactory(
            bearnVaultFactory.bearnAuctionFactory()
        );

        return auctionFactory.wantToAuction(address(asset));
    }
}
