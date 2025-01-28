// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IBearnVault} from "src/interfaces/IBearnVault.sol";

/// @title BearnVaultManager
/// @author Bearn.sucks
/// @notice Used to manage vaults, makes it easier to transfer ownership of all vaults if needed
contract BearnVaultManager is Ownable {
    enum Operation {
        Call,
        DelegateCall
    }

    /* ========== ERRORS ========== */
    error NotFactory();

    constructor(address _bearnVaultFactory) {
        bearnVaultFactory = _bearnVaultFactory;
    }

    address public immutable bearnVaultFactory;

    function registerVault(address bearnVault) external {
        require(msg.sender == bearnVaultFactory, NotFactory());

        IBearnVault(bearnVault).acceptManagement();
    }

    /// @notice Makes it so the Manager can do arbitrary calls
    /// @param to Tx destination
    /// @param value Tx value
    /// @param data Tx data
    /// @param operation Call or delegate call
    /// @param allowFailure Allow failure or revert
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bool allowFailure
    )
        public
        payable
        onlyOwner
        returns (bool success, bytes memory _returndata)
    {
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
