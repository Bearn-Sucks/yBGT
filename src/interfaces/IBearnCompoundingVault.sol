// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IBearnVault} from "src/interfaces/IBearnVault.sol";

interface IBearnCompoundingVault is IBearnVault {
    function auction() external returns (address);

    function lastClaimedBlock() external returns (uint256);

    function updatedEarned(address _account) external returns (address);
}
