// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CommonReportTrigger} from "@yearn/tokenized-strategy-periphery/ReportTrigger/CommonReportTrigger.sol";

interface IKeeper {
    /**
     * @notice Reports on a strategy.
     */
    function report(address _strategy) external returns (uint256, uint256);
}

contract Trigger {

    CommonReportTrigger public COMMON_TRIGGER = CommonReportTrigger(0xA045D4dAeA28BA7Bfe234c96eAa03daFae85A147);

    function reportTrigger(address _vault) public view returns (bool, bytes memory) {
        (bool trigger, bytes memory data) = COMMON_TRIGGER.strategyReportTrigger(_vault);
        if (trigger) {
            return (trigger, abi.encodeCall(IKeeper.report, (_vault)));
        }
        return (trigger, data);
    }
}
