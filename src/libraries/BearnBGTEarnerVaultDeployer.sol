// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {BearnBGTEarnerVault} from "src/BearnBGTEarnerVault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BearnBGTEarnerVaultDeployer
/// @author bearn.sucks
/// @notice Separated out from BearnVaultFactory to reduce contract size
library BearnBGTEarnerVaultDeployer {
    function deployVault(
        address stakingToken,
        address beraVault,
        address yBGT
    ) external returns (address yBGTVault) {
        // Create the vault
        yBGTVault = address(
            new BearnBGTEarnerVault(
                string.concat(
                    "Bearn ",
                    ERC20(stakingToken).symbol(),
                    " yBGT Vault"
                ),
                stakingToken,
                beraVault,
                address(yBGT)
            )
        );
    }
}
