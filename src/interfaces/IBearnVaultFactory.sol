// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnVaultFactory {
    /* ========== ERRORS ========== */
    error NoBeraVault();

    /* ========== EVENTS ========== */
    event NewVaults(
        address indexed stakingToken,
        address compoundingVault,
        address yBGTVault
    );

    function yBGT() external view returns (address);

    function beraVaultFactory() external view returns (address);

    function compoundingVaults(
        address stakingToken
    ) external view returns (address);

    function yBGTVaults(address stakingToken) external view returns (address);

    function isBearnVault(address stakingToken) external view returns (bool);

    function createVaults(
        address stakingToken
    ) external returns (address compoundingVault, address yBGTVault);
}
