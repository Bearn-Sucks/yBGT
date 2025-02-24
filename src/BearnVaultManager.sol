// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";

import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";
import {Authorized} from "@bearn/governance/contracts/Authorized.sol";

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

    address public immutable bearnVaultFactory;
    address public immutable bearnVoter;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _authorizer,
        address _bearnVaultFactory,
        address _bearnVoter
    ) Authorized(_authorizer) {
        bearnVaultFactory = _bearnVaultFactory;
        bearnVoter = _bearnVoter;
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
