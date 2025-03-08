// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnTips {
    function treasury() external view returns (address);

    function setTreasury(address newTreasury) external;

    function deposit(
        address bearnVault,
        address staking,
        uint256 amount,
        uint256 tips
    ) external;

    function rescue(address token, uint256 amount) external;
}
