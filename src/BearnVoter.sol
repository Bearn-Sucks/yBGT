// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

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

    IGovernor public immutable beraGovernance;
    IBearnVaultFactory public immutable bearnVaultFactory;

    /* ========== CONSTRUCTOR AND INITIALIZER ========== */

    constructor(address _bearnVaultFactory, address _beraGovernance) {
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

    /* ========== REDEEMING ========== */
    function redeem(
        address to,
        uint256 amount
    ) external onlyRole(REDEEMER_ROLE) {
        // wrap BERA to avoid any potential trouble with sending native BERA
    }
}
