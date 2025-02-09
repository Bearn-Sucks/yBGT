// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import {IGovernor as IBeraGovenor} from "@openzeppelin/contracts/governance/IGovernor.sol";

import {IBGT} from "@berachain/contracts/pol/BGT.sol";
import {WBERA} from "@berachain/contracts/WBERA.sol";

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";

/// @title BearnVoterManager
/// @author Bearn.sucks
/// @notice
///   Contract that manages BearnVoter and handles Berachain governance logic.
///   Can be swapped for another contract if Berachain ever upgrades its governance functions
contract BearnVoterManager is AccessControlEnumerable {
    /// @notice In charge of voting
    bytes32 public immutable MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IBGT public immutable bgt;
    WBERA public immutable wbera;
    IBeraGovenor public immutable beraGovernance;

    IBearnVoter public immutable bearnVoter;

    /* ========== CONSTRUCTOR AND INITIALIZER ========== */
    constructor(
        address _bgt,
        address _wbera,
        address _beraGovernance,
        address _bearnVoter
    ) {
        bgt = IBGT(_bgt);
        wbera = WBERA(payable(_wbera));
        beraGovernance = IBeraGovenor(_beraGovernance);

        bearnVoter = IBearnVoter(_bearnVoter);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    /* ========== VOTING ========== */

    function submitProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external onlyRole(MANAGER_ROLE) returns (uint256 proposalId) {
        bytes memory data = abi.encodeCall(
            beraGovernance.propose,
            (targets, values, calldatas, description)
        );

        (, bytes memory _returndata) = bearnVoter.execute(
            address(beraGovernance),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        return abi.decode(_returndata, (uint256));
    }

    function submitVotes(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) external onlyRole(MANAGER_ROLE) returns (uint256 balance) {
        bytes memory data = abi.encodeCall(
            beraGovernance.castVoteWithReasonAndParams,
            (proposalId, support, reason, params)
        );

        (, bytes memory _returndata) = bearnVoter.execute(
            address(beraGovernance),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        return abi.decode(_returndata, (uint256));
    }

    /* ========== BOOSTING ========== */
    function queueBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bytes memory data = abi.encodeCall(bgt.queueBoost, (pubkey, amount));

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    function cancelBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bytes memory data = abi.encodeCall(bgt.cancelBoost, (pubkey, amount));

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    /// @notice Activates already queued boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function activateBoost(bytes calldata pubkey) external returns (bool) {
        bytes memory data = abi.encodeCall(
            bgt.activateBoost,
            (address(this), pubkey)
        );

        (, bytes memory _returndata) = bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        return abi.decode(_returndata, (bool));
    }

    function queueDropBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bytes memory data = abi.encodeCall(
            bgt.queueDropBoost,
            (pubkey, amount)
        );

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    function cancelDropBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bytes memory data = abi.encodeCall(
            bgt.cancelDropBoost,
            (pubkey, amount)
        );

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    /// @notice Activates already queued boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function dropBoost(bytes calldata pubkey) external returns (bool) {
        bytes memory data = abi.encodeCall(
            bgt.dropBoost,
            (address(this), pubkey)
        );

        (, bytes memory _returndata) = bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        return abi.decode(_returndata, (bool));
    }
}
