// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ITokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/ITokenizedStaker.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IKodiakIsland} from "src/interfaces/IKodiakIsland.sol";
import {IUniswapQuoterV2} from "src/interfaces/IUniswapQuoterV2.sol";
import {IUniswapV3Pool} from "src/interfaces/IUniswapV3Pool.sol";
import {IKodiakRouter2} from "src/interfaces/IKodiakRouter2.sol";

/// @title Kodiak Island Zapper
/// @author bearn.sucks
/// @notice Zaps tokens into Kodiak Islands
contract KodiakZapper {
    using SafeERC20 for IERC20;

    IERC20 public constant wbera =
        IERC20(0x6969696969696969696969696969696969696969);

    IUniswapQuoterV2 public constant kodiakQuoter =
        IUniswapQuoterV2(0x644C8D6E501f7C994B74F5ceA96abe65d0BA662B);

    IKodiakRouter2 public constant kodiakRouter =
        IKodiakRouter2(payable(0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4));

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    function nativeZapIn(
        address kodiakIsland,
        uint256 tolerance
    ) public payable returns (uint256 shares) {
        (bool success, ) = address(wbera).call{value: msg.value}("");
        require(success, "WBERA deposit failed");

        return _zapIn(kodiakIsland, address(wbera), msg.value, tolerance);
    }

    function zapIn(
        address kodiakIsland,
        address inputToken,
        uint256 inputAmount,
        uint256 tolerance
    ) external returns (uint256 shares) {
        IERC20(inputToken).safeTransferFrom(
            msg.sender,
            address(this),
            inputAmount
        );

        return _zapIn(kodiakIsland, inputToken, inputAmount, tolerance);
    }

    function _zapIn(
        address kodiakIsland,
        address inputToken,
        uint256 inputAmount,
        uint256 tolerance
    ) internal returns (uint256 shares) {
        // find amount of tokens to sell
        Quote memory quote = calculateAmounts(
            kodiakIsland,
            inputToken,
            inputAmount,
            tolerance
        );

        // sell input tokens
        if (quote.sellAmount > 0) {
            IERC20(inputToken).forceApprove(
                address(kodiakRouter),
                quote.sellAmount
            );
            kodiakRouter.exactInputSingle(
                IKodiakRouter2.ExactInputSingleParams({
                    tokenIn: inputToken,
                    tokenOut: quote.tokenOut,
                    fee: quote.fee,
                    recipient: address(this),
                    amountIn: quote.sellAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: quote.sqrtPriceLimitX96
                })
            );
        }

        // find amount of island tokens to mint
        uint256 amount0 = quote.zeroForOne
            ? inputAmount - quote.sellAmount
            : quote.buyAmount;
        uint256 amount1 = quote.zeroForOne
            ? quote.buyAmount
            : inputAmount - quote.sellAmount;

        uint256 mintAmount;
        (amount0, amount1, mintAmount) = IKodiakIsland(kodiakIsland)
            .getMintAmounts(amount0, amount1);

        // mint kodiak island tokens to msg.sender
        IERC20(inputToken).forceApprove(
            kodiakIsland,
            quote.zeroForOne ? amount0 : amount1
        );
        IERC20(quote.tokenOut).forceApprove(
            kodiakIsland,
            quote.zeroForOne ? amount1 : amount0
        );

        IKodiakIsland(kodiakIsland).mint(mintAmount, msg.sender);

        // return unused tokens
        uint256 inputReturnAmount = IERC20(inputToken).balanceOf(address(this));

        if (inputReturnAmount > 0) {
            IERC20(inputToken).safeTransfer(msg.sender, inputReturnAmount);
        }

        uint256 outputReturnAmount = IERC20(quote.tokenOut).balanceOf(
            address(this)
        );

        if (outputReturnAmount > 0) {
            IERC20(quote.tokenOut).safeTransfer(msg.sender, outputReturnAmount);
        }

        return mintAmount;
    }

    struct Quote {
        uint256 sellAmount;
        uint256 buyAmount;
        address tokenOut;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        bool zeroForOne;
    }

    function calculateAmounts(
        address kodiakIsland,
        address tokenIn,
        uint256 inputAmount,
        uint256 tolerance // based on 1e18=100%
    ) public returns (Quote memory quote) {
        {
            IUniswapV3Pool kodiakPool = IUniswapV3Pool(
                IKodiakIsland(kodiakIsland).pool()
            );
            address token0 = kodiakPool.token0();
            quote.zeroForOne = tokenIn == token0;
            quote.tokenOut = quote.zeroForOne ? kodiakPool.token1() : token0;
            quote.fee = kodiakPool.fee();
            quote.sqrtPriceLimitX96 = quote.zeroForOne
                ? MIN_SQRT_RATIO + 1
                : MAX_SQRT_RATIO - 1;
        }

        // First check if the pool is already one-sided
        {
            (uint256 islandAmount0, uint256 islandAmount1) = IKodiakIsland(
                kodiakIsland
            ).getUnderlyingBalances();

            if (islandAmount0 == 0) {
                if (quote.zeroForOne) {
                    (
                        uint256 amountOut,
                        uint160 sqrtPriceX96After,
                        ,

                    ) = kodiakQuoter.quoteExactInputSingle(
                            IUniswapQuoterV2.QuoteExactInputSingleParams({
                                tokenIn: tokenIn,
                                tokenOut: quote.tokenOut,
                                amountIn: inputAmount,
                                fee: quote.fee,
                                sqrtPriceLimitX96: quote.sqrtPriceLimitX96
                            })
                        );

                    quote.sellAmount = inputAmount;
                    quote.buyAmount = amountOut;
                    quote.sqrtPriceLimitX96 = sqrtPriceX96After;
                    return quote;
                } else {
                    quote.sellAmount = 0;
                    quote.buyAmount = 0;
                    quote.sqrtPriceLimitX96 = 0;
                    return quote;
                }
            }

            if (islandAmount1 == 0) {
                if (quote.zeroForOne) {
                    quote.sellAmount = 0;
                    quote.buyAmount = 0;
                    quote.sqrtPriceLimitX96 = 0;
                    return quote;
                } else {
                    (
                        uint256 amountOut,
                        uint160 sqrtPriceX96After,
                        ,

                    ) = kodiakQuoter.quoteExactInputSingle(
                            IUniswapQuoterV2.QuoteExactInputSingleParams({
                                tokenIn: tokenIn,
                                tokenOut: quote.tokenOut,
                                amountIn: inputAmount,
                                fee: quote.fee,
                                sqrtPriceLimitX96: quote.sqrtPriceLimitX96
                            })
                        );

                    quote.sellAmount = inputAmount;
                    quote.buyAmount = amountOut;
                    quote.sqrtPriceLimitX96 = sqrtPriceX96After;
                    return quote;
                }
            }
        }

        // The goal is to have the ratio of amount0/amount1 match islandAmount0/islandAmount1 after a few loops
        // most zaps should be done within a few loops if the price impact isn't too large
        // start with selling 50% of input tokens and iterate from there
        uint256 top = inputAmount;
        uint256 bot = 1;
        uint256 mid = inputAmount / 2;
        while (true) {
            (uint256 amountOut, uint160 sqrtPriceX96After, , ) = kodiakQuoter
                .quoteExactInputSingle(
                    IUniswapQuoterV2.QuoteExactInputSingleParams({
                        tokenIn: tokenIn,
                        tokenOut: quote.tokenOut,
                        amountIn: mid,
                        fee: quote.fee,
                        sqrtPriceLimitX96: quote.sqrtPriceLimitX96
                    })
                );
            uint256 inputRatio = ((inputAmount - mid) * 1e18) / amountOut;

            (uint256 islandAmount0, uint256 islandAmount1) = IKodiakIsland(
                kodiakIsland
            ).getUnderlyingBalancesAtPrice(sqrtPriceX96After);
            uint256 islandRatio = quote.zeroForOne
                ? (islandAmount0 * 1e18) / islandAmount1
                : (islandAmount1 * 1e18) / islandAmount0;

            uint256 differenceOfRatios = (islandRatio * 1e18) / inputRatio;

            differenceOfRatios = differenceOfRatios > 1e18
                ? differenceOfRatios - 1e18
                : 1e18 - differenceOfRatios;

            if (differenceOfRatios <= tolerance) {
                quote.sellAmount = mid;
                quote.buyAmount = amountOut;
                quote.sqrtPriceLimitX96 = sqrtPriceX96After;
                return quote;
            }

            if (inputRatio > islandRatio) {
                bot = mid;
                mid = (mid + top) / 2;
            } else {
                top = mid;
                mid = (mid + bot) / 2;
            }
        }
    }
}
