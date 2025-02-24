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

contract StakedBearnBGT is TokenizedStaker {
    using SafeERC20 for IERC20;

    IBearnVoter public immutable bearnVoter;
    IBearnBGT public immutable yBGT;
    IERC20 public immutable honey;
    IBearnVaultManager public immutable bearnVaultManager;

    Auction public immutable auction;

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

        // Use Yearn AuctionFactory to deploy an Auction
        auction = Auction(
            AuctionFactory(0xCfA510188884F199fcC6e750764FAAbE6e56ec40)
                .createNewAuction(
                    address(yBGT),
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
        voterManager.getReward();

        // Kick off an auction if possible;
        _kickAuction();

        // report total assets
        _totalAssets = yBGT.balanceOf(address(this));
    }

    /// @dev Kick an auction
    function _kickAuction() internal {
        uint256 _balance = honey.balanceOf(address(this));
        honey.safeTransfer(address(auction), _balance);

        auction.kick(address(honey));
    }
}
