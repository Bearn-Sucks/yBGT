// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {BearnVault} from "src/BearnVault.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {BearnBGTEarnerVault} from "src/BearnBGTEarnerVault.sol";

import {BearnCompoundingVaultDeployer} from "src/libraries/BearnCompoundingVaultDeployer.sol";
import {BearnBGTEarnerVaultDeployer} from "src/libraries/BearnBGTEarnerVaultDeployer.sol";

import {IBearnVaultManager} from "src/interfaces/IBearnVaultManager.sol";
import {IBearnAuctionFactory} from "src/interfaces/IBearnAuctionFactory.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnCompoundingVault} from "src/interfaces/IBearnCompoundingVault.sol";

/// @title BearnTips
/// @author bearn.sucks
/// @notice Help us afford a UI dev
contract BearnTips is Authorized {
    using SafeERC20 for IERC20;

    event Tipped(address indexed tipper, address indexed token, uint256 amount);

    address public treasury;

    constructor(address _authorizer) Authorized(_authorizer) {
        treasury = msg.sender;
    }

    function setTreasury(
        address newTreasury
    ) external isAuthorized(MANAGER_ROLE) {
        treasury = newTreasury;
    }

    function deposit(
        address bearnVault,
        address staking,
        uint256 amount,
        uint256 tips
    ) external {
        IERC20(staking).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(staking).safeApprove(bearnVault, amount);

        uint256 output = IBearnVault(bearnVault).deposit(amount, address(this));

        if (tips > 0) {
            uint256 tipAmount = (output * (tips)) / (tips + 100);
            output -= tipAmount;
            IBearnVault(bearnVault).transfer(treasury, tipAmount);

            emit Tipped(msg.sender, staking, tipAmount);
        }

        IBearnVault(bearnVault).transfer(msg.sender, output);
    }

    function rescue(
        address token,
        uint256 amount
    ) external isAuthorized(MANAGER_ROLE) {
        IERC20(token).safeTransfer(treasury, amount);
    }
}
