// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBeraVaultFactory is IRewardVaultFactory {
    /// @notice The VAULT MANAGER role.
    function VAULT_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The VAULT PAUSER role.
    function VAULT_PAUSER_ROLE() external view returns (bytes32);

    /// @notice The beacon address.
    function beacon() external view returns (address);

    /// @notice The BGT token address.
    function bgt() external view returns (address);

    /// @notice The distributor address.
    function distributor() external view returns (address);

    /// @notice The BeaconDeposit contract address.
    function beaconDepositContract() external view returns (address);

    /// @notice Mapping of staking token to vault address.
    function getVault(address stakingToken) external view returns (address);

    /// @notice Array of all vaults that have been created.
    function allVaults(uint256 index) external view returns (address);
}
