// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBeraWeightedPool} from "src/interfaces/IBeraWeightedPool.sol";
import {IBexVault} from "src/interfaces/IBexVault.sol";

import {IPythOracle} from "src/interfaces/IPythOracle.sol";
import {IUniswapV3Factory} from "src/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "src/interfaces/IUniswapV3Pool.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";
import {IStakedBearnBGT} from "src/interfaces/IStakedBearnBGT.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

/// @title BearnUIControlCentre
/// @author bearn.sucks
/// @notice Used as a quick place to control static UI
contract BearnUIControlCentre is Authorized {
    using EnumerableSet for EnumerableSet.AddressSet;

    error UnequalLengths();

    event WhitelistChanged(address indexed stakingToken, bool state);

    ERC20 public constant wbera =
        ERC20(0x6969696969696969696969696969696969696969);

    ERC20 public immutable honey;

    IBearnBGT public immutable yBGT;

    IStakedBearnBGT public immutable styBGT;

    IBexVault public constant bexVault =
        IBexVault(payable(0x4Be03f781C497A489E3cB0287833452cA9B9E80B));

    IPythOracle public constant pythOracle =
        IPythOracle(0x2880aB155794e7179c9eE2e38200202908C17B43);

    IUniswapV3Factory public constant kodiakFactory =
        IUniswapV3Factory(0xD84CBf0B02636E7f53dB9E5e45A616E05d710990);

    EnumerableSet.AddressSet whitelistedStakes;

    mapping(address stake => string) public nameOverrides;

    mapping(address token => bytes32) public pythOracleIds;

    constructor(address _authorizer, address _styBGT) Authorized(_authorizer) {
        styBGT = IStakedBearnBGT(_styBGT);
        yBGT = IBearnBGT(IStakedBearnBGT(_styBGT).yBGT());
        honey = ERC20(IStakedBearnBGT(_styBGT).honey());
    }

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

    function styBGTApr() external view returns (uint256) {
        // fetch reward rate (using lastRewardRate as rewardRate)
        uint256 rewardRate = styBGT.rewardData(address(honey)).lastRewardRate;

        // fetch staking token amount
        uint256 stakedAmount = styBGT.totalSupply();

        // fetch prices
        uint256 yBGTPrice = getYBGTPrice();

        // calculate apr
        uint256 tvl = yBGTPrice * stakedAmount;

        // assuming $1 per HONEY, this is just for UI visualization so it's fine
        uint256 rewardsPerYearUsd = (rewardRate * 1e18 * 365 days) / 1e18;

        return (rewardsPerYearUsd * 1e18) / tvl; // apr in 1e18 (1e18=100%)
    }

    function getApr(address bearnVault) external view returns (uint256) {
        IBeraVault beraVault = IBeraVault(IBearnVault(bearnVault).beraVault());

        // fetch reward rate
        uint256 rewardRate = yBGT.previewWrap(
            bearnVault,
            beraVault.rewardRate()
        );

        // fetch staking token amount
        uint256 stakedAmount = beraVault.totalSupply();

        // fetch prices
        uint256 yBGTPrice = getYBGTPrice();
        uint256 lpPrice = getBexLpPrice(beraVault.stakeToken());

        // calculate apr
        uint256 tvl = lpPrice * stakedAmount;

        uint256 rewardsPerYearUsd = (rewardRate * yBGTPrice * 365 days) / 1e18;

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

    // reports token price at 1e18, not normalized to token's decimals
    function getYBGTPrice() public view returns (uint256) {
        uint256 beraPrice = getPythPrice(address(wbera));

        address token0 = address(wbera) > address(yBGT)
            ? address(yBGT)
            : address(wbera);
        address token1 = address(wbera) > address(yBGT)
            ? address(wbera)
            : address(yBGT);

        address pool = kodiakFactory.getPool(token0, token1, 3000);

        // return bera price if there is no pool
        if (pool == address(0)) {
            return beraPrice;
        }

        (uint256 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        uint256 priceX96 = FixedPointMathLib.fullMulDiv(
            sqrtPriceX96,
            sqrtPriceX96,
            2 ** 96
        );

        // normalize it to 1e18 instead of X96
        uint256 yBGTRatio = FixedPointMathLib.fullMulDiv(
            priceX96,
            1e18,
            2 ** 96
        );

        return FixedPointMathLib.fullMulDiv(yBGTRatio, beraPrice, 1e18);
    }
}
