// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnUIControlCentre {
    error UnequalLengths();

    event WhitelistChanged(address indexed stakingToken, bool state);

    function wbera() external view returns (address);

    function bexVault() external view returns (address);

    function pythOracle() external view returns (address);

    function nameOverrides(address stake) external view returns (string memory);

    function pythOracleIds(address stake) external view returns (bytes32);

    function getAllWhitelistedStakes() external view returns (address[] memory);

    function getAllWhitelistedStakesLength() external view returns (uint256);

    function getWhitelistedStake(uint256 index) external view returns (address);

    function adjustWhitelists(
        address[] calldata stakingTokens,
        bool[] calldata states
    ) external;

    function adjustWhitelist(address stakingToken, bool state) external;

    function setNameOverride(
        address stakingToken,
        string memory nameOverride
    ) external;

    function setPythOracleId(address token, bytes32 oracleId) external;

    function getApr(address bearnVault) external view returns (uint256);

    function getBexLpPrice(address bexPool) external view returns (uint256);

    function getPythPrice(address token) external view returns (uint256);
}
