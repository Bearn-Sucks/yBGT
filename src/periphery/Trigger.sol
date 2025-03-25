// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {CommonReportTrigger} from "@yearn/tokenized-strategy-periphery/ReportTrigger/CommonReportTrigger.sol";

interface IKeeper {
    /**
     * @notice Reports on a strategy.
     */
    function report(address _strategy) external returns (uint256, uint256);
}

contract Trigger {
    IBearnVaultFactory public immutable FACTORY;
    IKeeper public immutable KEEPER;

    CommonReportTrigger public COMMON_TRIGGER = CommonReportTrigger(0xA045D4dAeA28BA7Bfe234c96eAa03daFae85A147);

    constructor(address _factory) {
        FACTORY = IBearnVaultFactory(_factory);
        KEEPER = IKeeper(FACTORY.keeper());
    }

    function reportTrigger(address _vault) public view returns (bool, bytes memory) {
        (bool trigger, bytes memory data) = COMMON_TRIGGER.strategyReportTrigger(_vault);
        if (trigger) {
            return (trigger, abi.encodeCall(IKeeper.report, (_vault)));
        }
        return (trigger, data);
    }

    function handleCompoundingReports() external {
        address[] memory vaults = FACTORY.getAllCompoundingVaults();
        for (uint256 i; i < vaults.length; i++) {
            (bool trigger, ) = COMMON_TRIGGER.strategyReportTrigger(vaults[i]);
            if (trigger) {
                try KEEPER.report(vaults[i]) {} catch {}
            }
        }
    }

    function handleBGTEarnerReports() external {
        address[] memory vaults = FACTORY.getAllBgtEarnerVaults();
        for (uint256 i; i < vaults.length; i++) {
            (bool trigger, ) = COMMON_TRIGGER.strategyReportTrigger(vaults[i]);
            if (trigger) {
                try KEEPER.report(vaults[i]) {} catch {}
            }
        }
    }
}
