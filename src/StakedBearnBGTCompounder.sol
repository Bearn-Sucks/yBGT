// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IStakedBearnBGT} from "src/interfaces/IStakedBearnBGT.sol";
import {TokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/TokenizedStaker.sol";
import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";
import {AuctionFactory} from "@yearn/tokenized-strategy-periphery/Auctions/AuctionFactory.sol";

import {IBearnVaultManager} from "src/interfaces/IBearnVaultManager.sol";

/// @title StakedBearnBGTCompounder
/// @author bearn.sucks
/// @notice A contract for users to stake and get rewards from berachin for their styBGT, and autocompounds it for more styBGT
/// @dev This contract deposits into styBGT and auto-compounds the honey into more styBGT
contract StakedBearnBGTCompounder is TokenizedStaker {
    using SafeERC20 for IERC20;

    IStakedBearnBGT public immutable styBGT;
    IERC20 public immutable honey;
    IBearnVaultManager public immutable bearnVaultManager;

    Auction public auction;

    constructor(
        address _ybgt,
        address _styBGT,
        address _bearnVaultManager,
        address _honey
    ) TokenizedStaker(_ybgt, "styBGT Compounder") {
        honey = IERC20(_honey);
        styBGT = IStakedBearnBGT(_styBGT);
        bearnVaultManager = IBearnVaultManager(_bearnVaultManager);

        // Use Yearn AuctionFactory to deploy an Auction
        // Sell into yBGT
        auction = Auction(
            AuctionFactory(0xCfA510188884F199fcC6e750764FAAbE6e56ec40)
                .createNewAuction(
                    address(_ybgt),
                    address(this),
                    address(this),
                    1 days,
                    1e6
                )
        );

        // Enable honey auctions
        auction.enable(address(honey));

        // Transfer auction ownership
        auction.transferGovernance(address(bearnVaultManager));

        /// @dev don't forget to accept auction's governance on bearnVaultManager
    }

    function _deployFunds(uint256 amount) internal override {
        styBGT.deposit(asset.balanceOf(address(this)), address(this));
    }

    function _freeFunds(uint256 amount) internal override {
        // Use previewWithdraw to round up.
        uint256 shares = styBGT.previewWithdraw(amount);

        shares = Math.min(shares, styBGT.balanceOf(address(this)));

        styBGT.redeem(shares, address(this), address(this));
    }

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        // Call getReward() to transfer honey to this address
        styBGT.getReward();

        // Kick off an auction if possible;
        if (!auction.isActive(address(honey))) {
            _kickAuction();
        }

        uint256 excessAmount = asset.balanceOf(address(this));
        if (excessAmount > 0) {
            styBGT.deposit(excessAmount, address(this));
        }

        // report total assets
        _totalAssets = styBGT.convertToAssets(styBGT.balanceOf(address(this)));
    }

    /// @dev Kick an auction
    function _kickAuction() internal {
        uint256 _balance = honey.balanceOf(address(this));

        if (_balance > 0) {
            honey.safeTransfer(address(auction), _balance);

            auction.kick(address(honey));
        }
    }

    function setAuction(address _auction) external onlyManagement {
        if (address(auction) != address(0)) {
            require(
                auction.want() == address(asset) ||
                    auction.want() == address(styBGT),
                "Invalid auction"
            );
        }
        auction = Auction(_auction);
    }
}
