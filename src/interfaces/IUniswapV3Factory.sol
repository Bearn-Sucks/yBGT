// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IUniswapV3Factory {
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    function defaultFeeProtocol() external view returns (uint32);

    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

    function feeAmountTickSpacing(uint24) external view returns (int24);

    function getPool(address, address, uint24) external view returns (address);

    function owner() external view returns (address);

    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );

    function setDefaultFeeProtocol(uint32 _fee) external;

    function setOwner(address _owner) external;
}
