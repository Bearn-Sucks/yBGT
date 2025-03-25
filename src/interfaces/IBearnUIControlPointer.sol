// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnUIControlPointer {
    function uiControls() external view returns (address);

    function setUIControls() external;
}
