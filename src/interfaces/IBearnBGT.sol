// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IBearnBGT is IERC20, IERC20Permit, IAccessControlEnumerable {
    error NoBeraVault();
    error NoBGT();

    function MANAGEMENT_ROLE() external view returns (bytes32);

    function beraVaultFactory() external view returns (address);

    function bearnVoter() external view returns (address);

    function wrap(address stakingToken) external returns (uint256 amount);

    function redeem(uint256 amount) external returns (uint256 outputAmount);

    function previewRedeem(
        uint256 amount
    ) external view returns (uint256 outputAmount);
}
