// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";

import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";
import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";

import {BearnExecutor} from "src/bases/BearnExecutor.sol";

/// @title BearnVaultManager
/// @author Bearn.sucks
/// @notice Used to manage vaults, makes it easier to transfer ownership of all vaults if needed
contract BearnVaultManager is BearnExecutor, Authorized {
    /* ========== ERRORS ========== */

    error NotFactory();

    /* ========== Events ========== */

    event UpdateEmergencyAdmin(address indexed newEmergencyAdmin);

    address public immutable bearnVaultFactory;
    address public immutable bearnVoter;
    address public emergencyAdmin;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _authorizer,
        address _emergencyAdmin,
        address _bearnVaultFactory,
        address _bearnVoter
    ) Authorized(_authorizer) {
        emergencyAdmin = _emergencyAdmin;
        bearnVaultFactory = _bearnVaultFactory;
        bearnVoter = _bearnVoter;

        emit UpdateEmergencyAdmin(_emergencyAdmin);
    }

    function registerVault(address bearnVault) external {
        require(
            msg.sender == bearnVaultFactory ||
                BearnAuthorizer(AUTHORIZER).isAuthorized(
                    MANAGER_ROLE,
                    msg.sender
                ),
            NotFactory()
        );

        IBearnVault(bearnVault).acceptManagement();
        address treasury = IBearnVoter(bearnVoter).treasury();
        IBearnVault(bearnVault).setPerformanceFeeRecipient(treasury);
        IBearnVault(bearnVault).setEmergencyAdmin(emergencyAdmin);
    }

    function registerAuction(address auction) external {
        require(
            msg.sender ==
                IBearnVaultFactory(bearnVaultFactory).bearnAuctionFactory() ||
                BearnAuthorizer(AUTHORIZER).isAuthorized(
                    MANAGER_ROLE,
                    msg.sender
                ),
            NotFactory()
        );

        Auction(auction).acceptGovernance();
    }

    /// @dev This function only changes the emergency admin for new vaults,
    /// txs should be queued via exeute() to update existing vaults
    /// @param _emergencyAdmin New emergency admin
    function setEmergencyAdmin(
        address _emergencyAdmin
    ) external isAuthorized(MANAGER_ROLE) {
        emergencyAdmin = _emergencyAdmin;
        emit UpdateEmergencyAdmin(_emergencyAdmin);
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
        isAuthorized(MANAGER_ROLE)
        returns (bool success, bytes memory _returndata)
    {
        return _execute(to, value, data, operation, allowFailure);
    }
}
