// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BearnCompoundingVaultDeployer
/// @author bearn.sucks
/// @notice Separated out from BearnVaultFactory to reduce contract size
library BearnCompoundingVaultDeployer {
    function deployVault(
        address stakingToken,
        address beraVault,
        address yBGT
    ) external returns (address compoundingVault) {
        // Create the vault
        compoundingVault = address(
            new BearnCompoundingVault(
                string.concat(
                    "Bearn ",
                    ERC20(stakingToken).symbol(),
                    " Compounding Vault"
                ),
                string.concat("bc", ERC20(stakingToken).symbol()),
                stakingToken,
                beraVault,
                address(yBGT)
            )
        );
    }
}
