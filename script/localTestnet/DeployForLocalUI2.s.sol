// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Script, console, stdJson} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {IBeraVaultFactory} from "src/interfaces/IBeraVaultFactory.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";

import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";

import {BearnVaultFactory} from "src/BearnVaultFactory.sol";
import {BearnAuctionFactory} from "src/BearnAuctionFactory.sol";
import {BearnVaultManager} from "src/BearnVaultManager.sol";
import {BearnVoter} from "src/BearnVoter.sol";
import {BearnVoterManager} from "src/BearnVoterManager.sol";
import {BearnBGT} from "src/BearnBGT.sol";
import {BearnBGTFeeModule} from "src/BearnBGTFeeModule.sol";
import {StakedBearnBGT} from "src/StakedBearnBGT.sol";

import {BearnUIControlCentre} from "src/periphery/BearnUIControlCentre.sol";
import {BearnTips} from "src/periphery/BearnTips.sol";

import {DeployScript} from "script/Deployment.s.sol";
import {LocalUIDeployment} from "script/localTestnet/DeployForLocalUI.s.sol";

import {ERC20} from "@openzeppelin-yearn/contracts/token/ERC20/ERC20.sol";

contract LocalUIDeployment2 is LocalUIDeployment {
    using stdJson for string;

    function setUp() public virtual override {
        super.setUp();
    }

    function run() public virtual override {
        deployVaults(existingDeployment);
        BearnUIControlCentre uiControl = deployUIControl(existingDeployment);
    }
}
