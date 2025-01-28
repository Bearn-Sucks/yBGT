// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

/// @notice Stand-in for Yearn's old factory, only needed to retrieve protocol fees

contract MockProtocolFees {
    address public feeRecipient;

    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
    }

    function protocol_fee_config()
        external
        view
        returns (uint16 feeInBps, address recipient)
    {
        return (500, feeRecipient);
    }
}
