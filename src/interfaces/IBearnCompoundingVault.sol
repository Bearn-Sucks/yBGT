// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IBearnVault} from "src/interfaces/IBearnVault.sol";

interface IBearnCompoundingVault is IBearnVault {
    /* ========== ERRORS ========== */

    error AuctionNotDeployed();

    function auctionFactory() external returns (address);

    function auction() external returns (address);

    /* ========== MANAGEMENT ACTIONS ========== */
    function enableAuction() external;

    function disableAuction() external;

    function setStartingPrice(uint256 _startingPrice) external;

    function sweepFromAuction(address _token) external;
}
