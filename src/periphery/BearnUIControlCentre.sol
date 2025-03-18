// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBeraWeightedPool} from "src/interfaces/IBeraWeightedPool.sol";
import {IBexVault} from "src/interfaces/IBexVault.sol";

import {IPythOracle} from "src/interfaces/IPythOracle.sol";

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

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title BearnUIControlCentre
/// @author bearn.sucks
/// @notice Used as a quick place to control static UI
contract BearnUIControlCentre is Authorized {
    using EnumerableSet for EnumerableSet.AddressSet;

    error UnequalLengths();

    event WhitelistChanged(address indexed stakingToken, bool state);

    ERC20 public constant wbera =
        ERC20(0x6969696969696969696969696969696969696969);

    IBexVault public constant bexVault =
        IBexVault(payable(0x4Be03f781C497A489E3cB0287833452cA9B9E80B));

    IPythOracle public constant pythOracle =
        IPythOracle(0x2880aB155794e7179c9eE2e38200202908C17B43);

    EnumerableSet.AddressSet whitelistedStakes;

    mapping(address stake => string) public nameOverrides;

    mapping(address token => bytes32) public pythOracleIds;

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
    ) external isAuthorized(MANAGER_ROLE) {
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

    function setNameOverride(
        address stakingToken,
        string memory nameOverride
    ) external isAuthorized(MANAGER_ROLE) {
        nameOverrides[stakingToken] = nameOverride;
    }

    function setPythOracleId(
        address token,
        bytes32 oracleId
    ) external isAuthorized(MANAGER_ROLE) {
        pythOracleIds[token] = oracleId;
    }

    function getApr(address bearnVault) external view returns (uint256) {
        IBeraVault beraVault = IBeraVault(IBearnVault(bearnVault).beraVault());

        // fetch reward rate
        uint256 rewardRate = beraVault.rewardRate();

        // fetch staking token amount
        uint256 stakedAmount = beraVault.totalSupply();

        // fetch prices
        uint256 beraPrice = getPythPrice(address(wbera));
        uint256 lpPrice = getBexLpPrice(beraVault.stakeToken());

        // calculate apr
        uint256 tvl = lpPrice * stakedAmount;

        uint256 rewardsPerYearUsd = (rewardRate * beraPrice * 365 days) / 1e18;

        return (rewardsPerYearUsd * 1e18) / tvl; // apr in 1e18 (1e18=100%)
    }

    // reports LP token price at 1e18
    function getBexLpPrice(address bexPool) public view returns (uint256) {
        bytes32 poolId = IBeraWeightedPool(bexPool).getPoolId();
        (address[] memory tokens, uint256[] memory amounts, ) = bexVault
            .getPoolTokens(poolId);
        uint256[] memory weights;

        try IBeraWeightedPool(bexPool).getNormalizedWeights() returns (
            uint256[] memory _weights
        ) {
            weights = _weights;
        } catch {
            // assume stable pool with equal weighting if failed
            weights = new uint256[](tokens.length);
            for (uint256 i = 0; i < tokens.length; i++) {
                weights[i] = 1e18 / tokens.length;
            }
        }

        uint256 totalSupply = IBeraWeightedPool(bexPool).getActualSupply();

        // loop through tokens to find one with an oracle
        for (uint256 i; i < tokens.length; i++) {
            uint256 pricePerToken = getPythPrice(tokens[i]);

            // skip if there is no oracle for this token
            if (pricePerToken == 0) {
                continue;
            }
            uint256 decimals = ERC20(tokens[i]).decimals();

            // can return price for the whole LP based on weightings
            uint256 pricePerLpToken = (((amounts[i] * pricePerToken * 1e18) /
                (10 ** decimals)) * 1e18) /
                totalSupply /
                weights[i];

            return pricePerLpToken;
        }

        // if no oracle found, return 0
        return 0;
    }

    // reports token price at 1e18, not normalized to token's decimals
    function getPythPrice(address token) public view returns (uint256) {
        bytes32 oracleId = pythOracleIds[token];

        // return 0 if there is no oracle registered for this token
        if (oracleId == bytes32(0)) {
            return 0;
        }

        // using unsafe price since this is just informational for UI
        IPythOracle.Price memory answer = pythOracle.getPriceUnsafe(oracleId);

        uint256 pricePerToken = uint256(int256(answer.price) * 1e18) /
            10 ** uint256(int256(-answer.expo));

        return pricePerToken;
    }
}
