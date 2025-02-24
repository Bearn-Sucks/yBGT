// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnVoterManager {
    function MANAGER_ROLE() external view returns (bytes32);

    function bgt() external view returns (bytes32);

    function bgtStaker() external view returns (bytes32);

    function wbera() external view returns (bytes32);

    function honey() external view returns (bytes32);

    function beraGovernance() external view returns (bytes32);

    function bearnVoter() external view returns (bytes32);

    function styBGT() external view returns (bytes32);

    /* ========== VOTING ========== */

    function submitProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256 proposalId);

    function submitVotes(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) external returns (uint256 balance);

    /* ========== BOOSTING ========== */
    function queueBoost(bytes calldata pubkey, uint128 amount) external;

    function cancelBoost(bytes calldata pubkey, uint128 amount) external;

    /// @notice Activates already queued boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function activateBoost(bytes calldata pubkey) external returns (bool);

    function queueDropBoost(bytes calldata pubkey, uint128 amount) external;

    function cancelDropBoost(bytes calldata pubkey, uint128 amount) external;

    /// @notice Activates already queued boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function dropBoost(bytes calldata pubkey) external returns (bool);

    /* ========== REWARDS ========== */
    function getReward() external returns (uint256);
}
