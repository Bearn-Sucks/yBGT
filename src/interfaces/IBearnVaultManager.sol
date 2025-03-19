// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IOwnable} from "src/interfaces/IOwnable.sol";

interface IBearnVaultManager is IOwnable {
    /* ========== ERRORS ========== */

    error NotFactory();
    error MaxFee();

    /* ========== Events ========== */

    event UpdateEmergencyAdmin(address indexed newEmergencyAdmin);
    event UpdatePerformanceFee(uint256 newPerformanceFee);

    enum Operation {
        Call,
        DelegateCall
    }

    function bearnVaultFactory() external view returns (address);

    function bearnVoter() external view returns (address);

    function emergencyAdmin() external view returns (address);

    function performanceFee() external view returns (uint16);

    function registerVault(address bearnVault) external;

    function syncVaultSettings(address[] calldata bearnVaults) external;

    function registerAuction(address auction) external;

    function setEmergencyAdmin(address _emergencyAdmin) external;

    function setPerformanceFee(uint256 _performanceFee) external;

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bool allowFailure
    ) external returns (bool success, bytes memory _returndata);
}
