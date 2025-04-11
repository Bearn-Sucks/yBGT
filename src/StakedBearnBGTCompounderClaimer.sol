// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";
import {AuctionFactory} from "@yearn/tokenized-strategy-periphery/Auctions/AuctionFactory.sol";
import {UniswapV3Swapper} from "@yearn/tokenized-strategy-periphery/swappers/UniswapV3Swapper.sol";

import {IVault} from "@yearn/vaults-v3/interfaces/IVault.sol";

import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";
import {IStakedBearnBGT} from "src/interfaces/IStakedBearnBGT.sol";
import {IStakedBearnBGTCompounder} from "src/interfaces/IStakedBearnBGTCompounder.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

contract StakedBearnBGTCompounderClaimer is Authorized, UniswapV3Swapper {
    using SafeERC20 for IERC20;

    bytes32 public immutable KEEPER_ROLE = keccak256("KEEPER_ROLE");

    Auction public auction;

    IERC20 public immutable honey;

    IERC20 public immutable wbera;

    IVault public immutable yBERA;

    IBearnBGT public immutable yBGT;

    IStakedBearnBGT public immutable styBGT;

    IStakedBearnBGTCompounder public immutable styBGTCompounder;

    bool public swap;

    constructor(
        address _authorizer,
        address _styBGTCompounder,
        address _yBera
    ) Authorized(_authorizer) {
        styBGTCompounder = IStakedBearnBGTCompounder(_styBGTCompounder);
        styBGT = IStakedBearnBGT(styBGTCompounder.asset());
        yBGT = IBearnBGT(styBGT.asset());
        honey = IERC20(styBGT.honey());
        yBERA = IVault(_yBera);
        wbera = IERC20(yBERA.asset());

        auction = Auction(0x7DD6B106c28c4e98465b899Ba35547BDceac09d2);

        base = address(wbera);
        router = 0xEd158C4b336A6FCb5B193A5570e3a571f6cbe690;

        _setUniFees(address(honey), address(wbera), 3000);
        _setUniFees(address(yBERA), address(yBGT), 3000);
    }

    function report() external isAuthorized(KEEPER_ROLE) {
        uint256[] memory rewards = styBGT.earnedMulti(
            address(styBGTCompounder)
        );

        styBGT.getRewardFor(address(styBGTCompounder));

        for (uint256 i = 0; i < rewards.length; i++) {
            address reward = styBGT.rewardTokens(i);
            uint256 balance = IERC20(reward).balanceOf(address(this));

            if (balance == 0) continue;

            if (reward == address(honey)) {
                if (swap) {
                    // Swap honey to wbera
                    base = address(wbera);
                    _swapFrom(address(honey), address(wbera), balance, 0);

                    // Deposit wbera into yBERA
                    uint256 wberaBalance = wbera.balanceOf(address(this));
                    wbera.forceApprove(address(yBERA), wberaBalance);
                    yBERA.deposit(wberaBalance, address(this));

                    // Swap yBera to yBGT
                    base = address(yBERA);
                    _swapFrom(
                        address(yBERA),
                        address(yBGT),
                        yBERA.balanceOf(address(this)),
                        0
                    );
                } else {
                    if (!auction.isActive(address(honey))) {
                        honey.safeTransfer(address(auction), balance);
                        auction.kick(address(honey));
                    }
                }
            } else if (
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

    function setSwap(bool _swap) external isAuthorized(MANAGER_ROLE) {
        swap = _swap;
    }

    function setBase(address _base) external isAuthorized(MANAGER_ROLE) {
        base = _base;
    }

    function setUniFees(
        address _token0,
        address _token1,
        uint24 _fee
    ) external isAuthorized(MANAGER_ROLE) {
        _setUniFees(_token0, _token1, _fee);
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
