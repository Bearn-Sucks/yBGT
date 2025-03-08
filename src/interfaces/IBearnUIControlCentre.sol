// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnUIControlCentre {
    function getAllWhitelistedStakes() external view returns (address[] memory);

    function getAllWhitelistedStakesLength() external view returns (uint256);

    function getWhitelistedStake(uint256 index) external view returns (address);

    function adjustWhitelists(
        address[] calldata stakingTokens,
        bool[] calldata states
    ) external;

    function adjustWhitelist(address stakingToken, bool state) external;
}
