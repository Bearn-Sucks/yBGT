// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";

contract BearnVoter {
    error NotBearnVault();

    IBearnVaultFactory public immutable bearnVaultFactory;

    constructor(address _bearnVaultFactory) {
        bearnVaultFactory = IBearnVaultFactory(_bearnVaultFactory);
    }
}
