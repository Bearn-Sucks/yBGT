// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";

import {Authorized} from "@bearn/governance/contracts/Authorized.sol";

import {BearnVault} from "src/BearnVault.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {BearnBGTEarnerVault} from "src/BearnBGTEarnerVault.sol";

import {BearnCompoundingVaultDeployer} from "src/libraries/BearnCompoundingVaultDeployer.sol";
import {BearnBGTEarnerVaultDeployer} from "src/libraries/BearnBGTEarnerVaultDeployer.sol";

import {IBearnVaultManager} from "src/interfaces/IBearnVaultManager.sol";
import {IBearnAuctionFactory} from "src/interfaces/IBearnAuctionFactory.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnCompoundingVault} from "src/interfaces/IBearnCompoundingVault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title BearnUIControlCentre
/// @author bearn.sucks
/// @notice Used as a quick place to control static UI
contract BearnUIControlCentre is Authorized {
    using EnumerableSet for EnumerableSet.AddressSet;

    error UnequalLengths();

    event WhitelistChanged(address indexed stakingToken, bool state);

    EnumerableSet.AddressSet whitelistedStakes;

    constructor(address _authorizer) Authorized(_authorizer) {}

    function getAllWhitelistedStakes()
        external
        view
        returns (address[] memory)
    {
        return whitelistedStakes.values();
    }

    function getAllWhitelistedStakesLength() external view returns (uint256) {
        return whitelistedStakes.length();
    }

    function getWhitelistedStake(
        uint256 index
    ) external view returns (address) {
        return whitelistedStakes.at(index);
    }

    function adjustWhitelists(
        address[] calldata stakingTokens,
        bool[] calldata states
    ) external isAuthorized(MANAGER_ROLE) {
        require(stakingTokens.length == states.length, UnequalLengths());
        uint256 length = stakingTokens.length;
        for (uint256 i = 0; i < length; i++) {
            _adjustWhitelist(stakingTokens[i], states[i]);
        }
    }

    function adjustWhitelist(
        address stakingToken,
        bool state
    ) public isAuthorized(MANAGER_ROLE) {
        _adjustWhitelist(stakingToken, state);
    }

    function _adjustWhitelist(address stakingToken, bool state) internal {
        if (state) {
            if (whitelistedStakes.add(stakingToken)) {
                emit WhitelistChanged(stakingToken, state);
            }
        } else {
            if (whitelistedStakes.remove(stakingToken)) {
                emit WhitelistChanged(stakingToken, state);
            }
        }
    }
}
