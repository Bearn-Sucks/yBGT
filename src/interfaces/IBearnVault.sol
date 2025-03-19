// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ITokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/ITokenizedStaker.sol";

interface IBearnVault is ITokenizedStaker {
    function bearnVaultFactory() external view returns (address);

    function beraVault() external view returns (address);

    function yBGT() external view returns (address);

    function stakingAsset() external view returns (address);
}
