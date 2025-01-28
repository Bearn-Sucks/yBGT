// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVault} from "@berachain/contracts/pol/interfaces/IRewardVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBeraVault is IRewardVault {
    /// @notice ERC20 token which users stake to earn rewards.
    function stakeToken() external view returns (address);

    /// @notice ERC20 token in which rewards are denominated and distributed.
    function rewardToken() external view returns (address);

    /// @notice The reward rate for the current reward period scaled by PRECISION.
    function rewardRate() external view returns (uint256);

    /// @notice The amount of undistributed rewards scaled by PRECISION.
    function undistributedRewards() external view returns (uint256);

    /// @notice The last updated reward per token scaled by PRECISION.
    function rewardPerTokenStored() external view returns (uint256);

    /// @notice The total supply of the staked tokens.
    function totalSupply() external view returns (uint256);

    /// @notice The end of the current reward period, where we need to start a new one.
    function periodFinish() external view returns (uint256);

    /// @notice The time over which the rewards will be distributed. Current default is 7 days.
    function rewardsDuration() external view returns (uint256);

    /// @notice The last time the rewards were updated.
    function lastUpdateTime() external view returns (uint256);
}
