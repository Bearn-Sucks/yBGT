// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnVaultFactory {
    /* ========== ERRORS ========== */

    error NotInitialized();
    error NoBeraVault();
    error AlreadyExists();

    /* ========== EVENTS ========== */

    event NewVaultManager(address newVaultManager);
    event NewAuctionFactory(address newAuctionFactory);
    event NewVaults(
        address indexed stakingToken,
        address compoundingVault,
        address yBGTVault
    );

    function beraVaultFactory() external view returns (address);

    function keeper() external view returns (address);

    function yBGT() external view returns (address);

    function bearnVaultManager() external view returns (address);

    function bearnAuctionFactory() external view returns (address);

    function stakingToCompoundingVaults(
        address stakingToken
    ) external view returns (address);

    function stakingToBGTEarnerVaults(
        address stakingToken
    ) external view returns (address);

    function isBearnVault(address bearnVault) external view returns (bool);

    function getAllCompoundingVaultsLength() external view returns (uint256);

    function getCompoundingVault(uint256 index) external view returns (address);

    function getAllCompoundingVaults() external view returns (address[] memory);

    function getAllBgtEarnerVaultsLength() external view returns (uint256);

    function getBgtEarnerVault(uint256 index) external view returns (address);

    function getAllBgtEarnerVaults() external view returns (address[] memory);

    function setVaultManager(address _newBearnVaultManager) external;

    function setAuctionFactory(address _newAuctionFactory) external;

    function createVaults(
        address stakingToken
    ) external returns (address compoundingVault, address yBGTVault);
}
