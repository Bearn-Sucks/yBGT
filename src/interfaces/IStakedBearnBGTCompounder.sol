// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ITokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/ITokenizedStaker.sol";

interface IStakedBearnBGTCompounder is ITokenizedStaker {
    function styBGT() external view returns (address);

    function honey() external view returns (address);

    function bearnVaultManager() external view returns (address);

    function auction() external view returns (address);
}
