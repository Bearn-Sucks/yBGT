// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";

import {IBearnAuctionFactory} from "src/interfaces/IBearnAuctionFactory.sol";

import {BearnVault} from "src/BearnVault.sol";

contract BearnCompoundingVault is BearnVault {
    using SafeERC20 for IERC20;

    constructor(
        string memory _name,
        string memory _symbol,
        address _asset,
        address _beraVault,
        address _yBGT
    ) BearnVault(_name, _symbol, _asset, _beraVault, _yBGT) {}

    /// @notice Override initialization since compounding vaults don't have yBGT as a reward
    function _initialize() internal override {}

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        // This claims the BGT to the Bearn Voter in return for yBGT
        yBGT.wrap(address(asset));

        Auction _auction = Auction(auction());

        if (
            address(_auction) == address(0) || // auction factory will deploy a new auction if one hasn't already been deployed
            !Auction(auction()).isActive(address(yBGT))
        ) {
            _kickAuction();
        }

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

        if (_balance > 0) {
            IERC20(yBGT).forceApprove(address(auctionFactory), _balance); // force approve is the new safeApprove in OZ

            auctionFactory.kickAuction(address(asset), _balance);
        }
    }

    function auction() public view returns (address) {
        IBearnAuctionFactory auctionFactory = IBearnAuctionFactory(
            bearnVaultFactory.bearnAuctionFactory()
        );

        return auctionFactory.wantToAuction(address(asset));
    }
}
