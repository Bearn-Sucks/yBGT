// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IBearnTreasury {
    error SafeERC20FailedOperation(address token);
    event RetrieveToken(address token, uint256 amount);

    function AUTHORIZER() external view returns (address);

    function TREASURY_APPROVER_ROLE() external view returns (bytes32);

    function TREASURY_RETRIEVER_ROLE() external view returns (bytes32);

    function claimRewards() external;

    function retrieveToken(address _token, address _to) external;

    function retrieveTokenExact(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setTokenApproval(
        address _token,
        address _spender,
        uint256 _amount
    ) external;

    function stake() external;

    function styBGT() external view returns (address);

    function wbera() external view returns (address);

    function yBGT() external view returns (address);

    receive() external payable;
}
