// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVault} from "@berachain/contracts/pol/interfaces/IRewardVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBearnVoter {
    function MANAGER_ROLE() external view returns (bytes32);

    function REDEEMER_ROLE() external view returns (bytes32);

    function beraGovernance() external view returns (address);

    function bearnVaultFactory() external view returns (address);

    function initialize(address redeemModule) external;

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

    function redeem(address to, uint256 amount) external;
}
