// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ITokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/ITokenizedStaker.sol";

interface IStakedBearnBGT is ITokenizedStaker {
    function yBGT() external view returns (address);

    function honey() external view returns (address);

    function bearnVaultManager() external view returns (address);

    function lastClaimedBlock() external view returns (uint256);

    function auction() external view returns (address);

    function getRewardFor(address user) external;
}
