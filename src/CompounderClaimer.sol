// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";
import {AuctionFactory} from "@yearn/tokenized-strategy-periphery/Auctions/AuctionFactory.sol";

import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";
import {IStakedBearnBGT} from "src/interfaces/IStakedBearnBGT.sol";
import {IStakedBearnBGTCompounder} from "src/interfaces/IStakedBearnBGTCompounder.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

contract CompounderClaimer is Authorized {
    using SafeERC20 for IERC20;
    bytes32 public immutable KEEPER_ROLE = keccak256("KEEPER_ROLE");

    Auction public auction;

    IERC20 public immutable honey;

    IBearnBGT public immutable yBGT;

    IStakedBearnBGT public immutable styBGT;

    IStakedBearnBGTCompounder public immutable styBGTCompounder;

    constructor(
        address _authorizer,
        address _styBGTCompounder
    ) Authorized(_authorizer) {
        styBGTCompounder = IStakedBearnBGTCompounder(_styBGTCompounder);
        styBGT = IStakedBearnBGT(styBGTCompounder.asset());
        yBGT = IBearnBGT(styBGT.asset());
        honey = IERC20(styBGT.honey());

        auction = Auction(
            AuctionFactory(0xCfA510188884F199fcC6e750764FAAbE6e56ec40)
                .createNewAuction(
                    address(yBGT),
                    address(this),
                    address(this),
                    1 days,
                    1_000
                )
        );

        // Enable honey auctions
        auction.enable(address(honey));

        // Transfer governance to styBGTCompounder management
        auction.transferGovernance(styBGTCompounder.management());
    }

    function report() external isAuthorized(KEEPER_ROLE) {
        styBGT.getRewardFor(address(styBGTCompounder));

        uint256[] memory rewards = styBGT.earnedMulti(
            address(styBGTCompounder)
        );

        styBGT.getRewardFor(address(styBGTCompounder));

        for (uint256 i = 0; i < rewards.length; i++) {
            address reward = styBGT.rewardTokens(i);
            uint256 balance = IERC20(reward).balanceOf(address(this));
            if (reward == address(honey)) {
                if (balance > 0 && !auction.isActive(address(honey))) {
                    honey.safeTransfer(address(auction), balance);
                    auction.kick(address(honey));
                }
                continue;
            }

            if (
                balance > 0 &&
                styBGTCompounder.rewardData(reward).rewardsDistributor ==
                address(this)
            ) {
                IERC20(reward).forceApprove(address(styBGTCompounder), balance);
                styBGTCompounder.notifyRewardAmount(reward, balance);
            }
        }

        // Redeploy any funds in the last auction.
        uint256 ybgtBalance = yBGT.balanceOf(address(this));
        if (ybgtBalance > 0) {
            IERC20(address(yBGT)).forceApprove(address(styBGT), ybgtBalance);
            styBGT.deposit(ybgtBalance, address(styBGTCompounder));
        }

        styBGTCompounder.report();
    }

    function setAuction(address _auction) external isAuthorized(MANAGER_ROLE) {
        if (_auction != address(0)) {
            require(
                auction.want() == address(styBGT.asset()) ||
                    auction.want() == address(styBGT.asset()),
                "Invalid auction"
            );
        }
        auction = Auction(_auction);
    }

    function rescue(address token) external isAuthorized(MANAGER_ROLE) {
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }
}
