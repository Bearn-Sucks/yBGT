// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnVaultFactory {
    /* ========== ERRORS ========== */

    error NotInitialized();
    error NoBeraVault();

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
