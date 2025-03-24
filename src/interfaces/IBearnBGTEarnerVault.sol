// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IBearnVault} from "src/interfaces/IBearnVault.sol";

interface IBearnBGTEarnerVault is IBearnVault {
    function updatedEarned(address _account) external view returns (uint256);

    function lastClaimedBlock() external view returns (uint256);
}
