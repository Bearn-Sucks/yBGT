// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IYBeraZapper {
    function styBera() external view returns (address);

    function yBera() external view returns (address);

    function wbera() external view returns (address);

    function nativeZapIn() external payable returns (uint256 shares);

    function zapIn(uint256 assets) external returns (uint256 shares);

    function zapOut(uint256 shares) external returns (uint256 assets);

    receive() external payable;
}
