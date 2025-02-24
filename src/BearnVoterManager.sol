// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IGovernor as IBeraGovenor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBGT} from "@berachain/contracts/pol/BGT.sol";
import {IBGTStaker} from "@berachain/contracts/pol/BGTStaker.sol";
import {WBERA} from "@berachain/contracts/WBERA.sol";

import {Authorized} from "@bearn/governance/contracts/Authorized.sol";

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";

/// @title BearnVoterManager
/// @author Bearn.sucks
/// @notice
///   Contract that manages BearnVoter and handles Berachain governance logic.
///   Can be swapped for another contract if Berachain ever upgrades its governance functions
contract BearnVoterManager is Authorized {
    IBGT public immutable bgt;
    IBGTStaker public immutable bgtStaker;
    WBERA public immutable wbera;
    IERC20 public immutable honey;
    IBeraGovenor public immutable beraGovernance;

    IBearnVoter public immutable bearnVoter;
    address public immutable styBGT;

    /* ========== CONSTRUCTOR AND INITIALIZER ========== */
    constructor(
        address _authorizer,
        address _bgt,
        address _bgtStaker,
        address _wbera,
        address _honey,
        address _beraGovernance,
        address _bearnVoter,
        address _styBGT
    ) Authorized(_authorizer) {
        bgt = IBGT(_bgt);
        bgtStaker = IBGTStaker(_bgtStaker);
        wbera = WBERA(payable(_wbera));
        honey = IERC20(_honey);
        beraGovernance = IBeraGovenor(_beraGovernance);
        styBGT = _styBGT;

        bearnVoter = IBearnVoter(_bearnVoter);
    }

    /* ========== VOTING ========== */

    function submitProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external isAuthorized(MANAGER_ROLE) returns (uint256 proposalId) {
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
    ) external isAuthorized(MANAGER_ROLE) returns (uint256 balance) {
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
    ) external isAuthorized(MANAGER_ROLE) {
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
    ) external isAuthorized(MANAGER_ROLE) {
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
    ) external isAuthorized(MANAGER_ROLE) {
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
    ) external isAuthorized(MANAGER_ROLE) {
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

    /* ========== REWARDS ========== */
    function getReward() external returns (uint256) {
        // Claim rewards
        bytes memory data = abi.encodeCall(bgtStaker.getReward, ());

        (, bytes memory _returndata) = bearnVoter.execute(
            address(bgtStaker),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        uint256 amount = abi.decode(_returndata, (uint256));

        // Send rewards to styBGT
        data = abi.encodeCall(IERC20.transfer, (address(styBGT), amount));
        bearnVoter.execute(
            address(honey),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        return amount;
    }
}
