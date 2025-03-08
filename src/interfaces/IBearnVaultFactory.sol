// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnVaultFactory {
    /* ========== ERRORS ========== */

    error NotInitialized();
    error NoBeraVault();
    error AlreadyExists();

    /* ========== EVENTS ========== */

    event NewVaults(
        address indexed stakingToken,
        address compoundingVault,
        address yBGTVault
    );

    function keeper() external view returns (address);

    function yBGT() external view returns (address);

    function bearnVaultManager() external view returns (address);

    function bearnAuctionFactory() external view returns (address);

    function beraVaultFactory() external view returns (address);

    function getAllCompoundingVaultsLength() external view returns (uint256);

    function getCompoundingVault(uint256 index) external view returns (address);

    function getAllCompoundingVaults() external view returns (address[] memory);

    function getAllBgtEarnerVaultsLength() external view returns (uint256);

    function getBgtEarnerVault(uint256 index) external view returns (address);

    function getAllBgtEarnerVaults() external view returns (address[] memory);

    function stakingToCompoundingVaults(
        address stakingToken
    ) external view returns (address);

    function stakingToBGTEarnerVaults(
        address stakingToken
    ) external view returns (address);

    function isBearnVault(address bearnVault) external view returns (bool);

    function createVaults(
        address stakingToken
    ) external returns (address compoundingVault, address yBGTVault);
}
