// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IBearnBGTFeeModule is IAccessControlEnumerable {
    function version() external pure returns (string memory);

    function wrapFee() external view returns (uint256);

    function redeemFee() external view returns (uint256);

    function previewWrap(
        address to,
        uint256 inputAmount
    ) external view returns (uint256 outputAmount, uint256 fee);

    function wrap(
        address to,
        uint256 inputAmount
    ) external returns (uint256 outputAmount, uint256 fee);

    function redeem(
        address to,
        uint256 inputAmount
    ) external returns (uint256 outputAmount, uint256 fee);

    function previewRedeem(
        address to,
        uint256 inputAmount
    ) external view returns (uint256 outputAmount, uint256 fee);
}
