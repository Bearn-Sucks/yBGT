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

        vm.startBroadcast(deployer);

        // BearnUIControlCentre uiControl = BearnUIControlCentre(
        //     0x764D962f591e4C17ec3c7187A5fC7F57cac9F8Db
        // );
        // console.log(
        //     uiControl.getApr(0x70244d4B342C14b77Aa1266b9c9Dc08593CDEFF4)
        // );

        uiControl.adjustWhitelist(
            0xfC4994e0A4780ba7536d7e79611468B6bde14CaE,
            false
        );
        uiControl.adjustWhitelist(
            0xA0cAbFc04Fc420b3d31BA431d18eB5bD33B3f334,
            false
        );

        uiControl.setTokenAddressOverride(
            0xff12470a969Dd362EB6595FFB44C82c959Fe9ACc,
            0x549943e04f40284185054145c6E4e9568C1D3241
        );

        // bool[] memory states = new bool[](stakes.length);
        // for (uint256 i = 0; i < stakes.length; i++) {
        //     states[i] = false;
        // }

        // // whitelist stakes
        // uiControl.adjustWhitelists(stakes, states);
    }

    function checkVaults(DeployedContracts memory c) public view {
        for (uint i = 0; i < stakes.length; i++) {
            address stakeToken = stakes[i];
            console.log("stakeToken", stakeToken);

            // skip if a bearn vault is already made
            if (
                c.vaultFactory.stakingToCompoundingVaults(stakeToken) !=
                address(0)
            ) {
                continue;
            }

            IBeraVault beraVault = IBeraVault(
                IBeraVaultFactory(beraVaultFactory).getVault(stakeToken)
            );

            // log and skip if a bera vault doesn't exist for the staking token
            if (address(beraVault) == address(0)) {
                console.log("no bera vault");
                continue;
            }
        }
    }
}
