// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

import {IBGT} from "@berachain/contracts/pol/BGT.sol";
import {WBERA} from "@berachain/contracts/WBERA.sol";

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";

/// @title BearnVoter
/// @author Bearn.sucks
/// @notice
///   Contract that holds the BGT backing yBGT and also votes with those BGT.
///   Should be behind a TransparentUpgradeable Proxy.
contract BearnVoter is AccessControlEnumerableUpgradeable {
    /// @notice In charge of voting
    bytes32 public immutable MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// @notice Redeem module
    bytes32 public immutable REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    IBGT public immutable bgt;
    WBERA public immutable wbera;
    IGovernor public immutable beraGovernance;

    IBearnVaultFactory public immutable bearnVaultFactory;

    /* ========== CONSTRUCTOR AND INITIALIZER ========== */

    constructor(
        address _bgt,
        address _wbera,
        address _beraGovernance,
        address _bearnVaultFactory
    ) {
        bgt = IBGT(_bgt);
        wbera = WBERA(payable(_wbera));
        beraGovernance = IGovernor(_beraGovernance);
        bearnVaultFactory = IBearnVaultFactory(_bearnVaultFactory);
    }

    /// @notice Should be called on upgrade with upgradeToAndCall()
    function initialize(address bearnBGT) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(REDEEMER_ROLE, bearnBGT);
    }

    /* ========== VOTING ========== */

    function submitProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external onlyRole(MANAGER_ROLE) returns (uint256 proposalId) {
        return beraGovernance.propose(targets, values, calldatas, description);
    }

    function submitVotes(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) external onlyRole(MANAGER_ROLE) returns (uint256 balance) {
        return
            beraGovernance.castVoteWithReasonAndParams(
                proposalId,
                support,
                reason,
                params
            );
    }

    /* ========== BOOSTING ========== */
    function queueBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bgt.queueBoost(pubkey, amount);
    }

    function cancelBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bgt.cancelBoost(pubkey, amount);
    }

    /// @notice Activates already queued boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function activateBoost(bytes calldata pubkey) external returns (bool) {
        return bgt.activateBoost(address(this), pubkey);
    }

    function queueDropBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bgt.queueDropBoost(pubkey, amount);
    }

    function cancelDropBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external onlyRole(MANAGER_ROLE) {
        bgt.cancelDropBoost(pubkey, amount);
    }

    /// @notice Activates already queued boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function dropBoost(bytes calldata pubkey) external returns (bool) {
        return bgt.dropBoost(address(this), pubkey);
    }

    /* ========== REDEEMING ========== */
    function redeem(
        address to,
        uint256 amount
    ) external onlyRole(REDEEMER_ROLE) {
        // wrap BERA to avoid any potential trouble with sending native BERA
        // BERA is warpped to wBERA in the receive() function
        bgt.redeem(address(this), amount);
        wbera.transfer(to, amount);
    }

    receive() external payable {
        wbera.deposit{value: msg.value}();
    }
}
