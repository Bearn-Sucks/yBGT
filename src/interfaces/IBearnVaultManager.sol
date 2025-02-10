// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IOwnable} from "src/interfaces/IOwnable.sol";

interface IBearnVaultManager is IOwnable {
    enum Operation {
        Call,
        DelegateCall
    }

    error NotFactory();

    function bearnVaultFactory() external view returns (address);

    function bearnVoter() external view returns (address);

    function registerVault(address bearnVault) external;

    function registerAuction(address auction) external;

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bool allowFailure
    ) external returns (bool success, bytes memory _returndata);
}
