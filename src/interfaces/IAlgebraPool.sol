// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IAlgebraPool {
    error alreadyInitialized();
    error arithmeticError();
    error bottomTickLowerThanMIN();
    error dynamicFeeActive();
    error dynamicFeeDisabled();
    error flashInsufficientPaid0();
    error flashInsufficientPaid1();
    error insufficientInputAmount();
    error invalidAmountRequired();
    error invalidHookResponse(bytes4 expectedSelector);
    error invalidLimitSqrtPrice();
    error invalidNewCommunityFee();
    error invalidNewTickSpacing();
    error liquidityAdd();
    error liquidityOverflow();
    error liquiditySub();
    error locked();
    error notAllowed();
    error notInitialized();
    error pluginIsNotConnected();
    error priceOutOfRange();
    error tickInvalidLinks();
    error tickIsNotInitialized();
    error tickIsNotSpaced();
    error tickOutOfRange();
    error topTickAboveMAX();
    error topTickLowerOrEqBottomTick();
    error transferFailed();
    error zeroAmountRequired();
    error zeroLiquidityActual();
    error zeroLiquidityDesired();
    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );
    event CommunityFee(uint16 communityFeeNew);
    event CommunityVault(address newCommunityVault);
    event Fee(uint16 fee);
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );
    event Initialize(uint160 price, int24 tick);
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );
    event Plugin(address newPluginAddress);
    event PluginConfig(uint8 newPluginConfig);
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 price,
        uint128 liquidity,
        int24 tick
    );
    event TickSpacing(int24 newTickSpacing);

    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount,
        bytes memory data
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function communityFeeLastTimestamp() external view returns (uint32);

    function communityVault() external view returns (address);

    function factory() external view returns (address);

    function fee() external view returns (uint16 currentFee);

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes memory data
    ) external;

    function getCommunityFeePending() external view returns (uint128, uint128);

    function getReserves() external view returns (uint128, uint128);

    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 lastFee,
            uint8 pluginConfig,
            uint16 communityFee,
            bool unlocked
        );

    function initialize(uint160 initialPrice) external;

    function isUnlocked() external view returns (bool unlocked);

    function liquidity() external view returns (uint128);

    function maxLiquidityPerTick() external view returns (uint128);

    function mint(
        address leftoversRecipient,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 liquidityDesired,
        bytes memory data
    )
        external
        returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);

    function nextTickGlobal() external view returns (int24);

    function plugin() external view returns (address);

    function positions(
        bytes32
    )
        external
        view
        returns (
            uint256 liquidity,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );

    function prevTickGlobal() external view returns (int24);

    function safelyGetStateOfAMM()
        external
        view
        returns (
            uint160 sqrtPrice,
            int24 tick,
            uint16 lastFee,
            uint8 pluginConfig,
            uint128 activeLiquidity,
            int24 nextTick,
            int24 previousTick
        );

    function setCommunityFee(uint16 newCommunityFee) external;

    function setCommunityVault(address newCommunityVault) external;

    function setFee(uint16 newFee) external;

    function setPlugin(address newPluginAddress) external;

    function setPluginConfig(uint8 newConfig) external;

    function setTickSpacing(int24 newTickSpacing) external;

    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountRequired,
        uint160 limitSqrtPrice,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);

    function swapWithPaymentInAdvance(
        address leftoversRecipient,
        address recipient,
        bool zeroToOne,
        int256 amountToSell,
        uint160 limitSqrtPrice,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);

    function tickSpacing() external view returns (int24);

    function tickTable(int16) external view returns (uint256);

    function tickTreeRoot() external view returns (uint32);

    function tickTreeSecondLayer(int16) external view returns (uint256);

    function ticks(
        int24
    )
        external
        view
        returns (
            uint256 liquidityTotal,
            int128 liquidityDelta,
            int24 prevTick,
            int24 nextTick,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token
        );

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalFeeGrowth0Token() external view returns (uint256);

    function totalFeeGrowth1Token() external view returns (uint256);
}
