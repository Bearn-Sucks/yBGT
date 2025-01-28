// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";

import {BearnVault} from "src/BearnVault.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnCompoundingVault} from "src/interfaces/IBearnCompoundingVault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BearnVaultFactory {
    /* ========== ERRORS ========== */
    error NoBeraVault();

    /* ========== EVENTS ========== */
    event NewVaults(
        address indexed stakingToken,
        address compoundingVault,
        address yBGTVault
    );

    ERC20 public immutable yBGT;
    IBeraVaultFactory public immutable beraVaultFactory;
    mapping(address stakingToken => address) compoundingVaults;
    mapping(address stakingToken => address) yBGTVaults;
    mapping(address bearnVaults => bool) isBearnVault;

    constructor(address _yBGT, address _beraVaultFactory) {
        yBGT = ERC20(_yBGT);
        beraVaultFactory = IBeraVaultFactory(_beraVaultFactory);
    }

    function createVaults(
        address stakingToken
    ) external returns (address compoundingVault, address yBGTVault) {
        // Check if BeraVault exists
        address beraVault = beraVaultFactory.getVault(stakingToken);
        require(beraVault != address(0), NoBeraVault());

        // Create the vaults
        compoundingVault = address(
            new BearnCompoundingVault(
                string.concat(
                    "Bearn ",
                    ERC20(stakingToken).symbol(),
                    " Compounding Vault"
                ),
                stakingToken,
                beraVault,
                address(yBGT)
            )
        );
        yBGTVault = address(
            new BearnVault(
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

        // Record the vaults
        compoundingVaults[stakingToken] = compoundingVault;
        yBGTVaults[stakingToken] = yBGTVault;
        isBearnVault[compoundingVault] = true;
        isBearnVault[yBGTVault] = true;

        emit NewVaults(stakingToken, compoundingVault, yBGTVault);
    }

    function report(address bearnVault) external {
        IBearnVault(bearnVault).report();
    }
}
