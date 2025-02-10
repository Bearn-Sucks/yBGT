// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}
