// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

/// @title Bearn Executor
/// @author Bearn.sucks
/// @notice Allows arbitrary functions to be executed
abstract contract BearnExecutor {
    enum Operation {
        Call,
        DelegateCall
    }

    /// @notice Makes it so the Manager can do arbitrary calls
    /// @param to Tx destination
    /// @param value Tx value
    /// @param data Tx data
    /// @param operation Call or delegate call
    /// @param allowFailure Allow failure or revert
    function _execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bool allowFailure
    ) internal returns (bool success, bytes memory _returndata) {
        if (operation == Operation.Call) {
            (success, _returndata) = to.call{value: value}(data);
        } else {
            (success, _returndata) = to.delegatecall(data);
        }

        // If the call reverted. Return the error.
        if (!allowFailure && !success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}
