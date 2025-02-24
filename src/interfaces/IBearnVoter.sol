// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnVoter {
    enum Operation {
        Call,
        DelegateCall
    }

    error NotVoterManager();

    event NewVoterManager(address indexed newVoterManager);
    event NewTreasury(address indexed newTreasury);

    function MANAGER_ROLE() external view returns (bytes32);

    function TIMELOCK_ROLE() external view returns (bytes32);

    function REDEEMER_ROLE() external view returns (bytes32);

    function bgt() external view returns (address);

    function wbera() external view returns (address);

    function beraGovernance() external view returns (address);

    function voterManager() external view returns (address);

    function treasury() external view returns (address);

    function setTreasury(address _treasury) external;

    function setVoterManager(address _voterManager) external;

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bool allowFailure
    ) external payable returns (bool success, bytes memory _returndata);

    function redeem(address to, uint256 amount) external;
}
