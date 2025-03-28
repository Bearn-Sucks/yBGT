// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnTips {
    event Tipped(address indexed tipper, address indexed token, uint256 amount);

    function treasury() external view returns (address);

    function setTreasury(address newTreasury) external;

    function deposit(
        address bearnVault,
        address staking,
        uint256 amount,
        uint256 tips
    ) external;

    function zapIntoStyBGTCompounder(uint256 amount) external returns (uint256);

    function zapOutFromStyBGTCompounder(
        uint256 amount
    ) external returns (uint256);

    function rescue(address token, uint256 amount) external;
}
