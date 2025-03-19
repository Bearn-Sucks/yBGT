// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

interface IBearnBGT is IERC20, IERC20Permit {
    error NoBeraVault();
    error NoBGT();

    event NewFeeModule(address newFeeModule);
    event NewTreasury(address newFeeRecipient);

    function MANAGER_ROLE() external view returns (bytes32);

    function beraVaultFactory() external view returns (address);

    function bearnVoter() external view returns (address);

    function feeModule() external view returns (address);

    function treasury() external view returns (address);

    function wrap(address stakingToken) external returns (uint256 amount);

    function redeem(uint256 amount) external returns (uint256 outputAmount);

    function previewWrap(
        address to,
        uint256 inputAmount
    ) external view returns (uint256 outputAmount);

    function previewRedeem(
        address to,
        uint256 amount
    ) external view returns (uint256 outputAmount);

    function maxRedeem() external view returns (uint256 maxAmount);

    function setFeeModule(address newFeeModule) external;

    function setFeeRecipient(address newFeeRecipient) external;
}
