// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBeraWeightedPool} from "src/interfaces/IBeraWeightedPool.sol";
import {IBexVault} from "src/interfaces/IBexVault.sol";

import {IPythOracle} from "src/interfaces/IPythOracle.sol";
import {IUniswapV3Factory} from "src/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "src/interfaces/IUniswapV3Pool.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnAuctionFactory} from "src/interfaces/IBearnAuctionFactory.sol";
import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";
import {IStakedBearnBGT} from "src/interfaces/IStakedBearnBGT.sol";
import {IKodiakIsland} from "src/interfaces/IKodiakIsland.sol";
import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";
import {IHypervisor} from "src/interfaces/IHypervisor.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

/// @title BearnUIControlCentre
/// @author bearn.sucks
/// @notice Used so the UI doesn't need to be updated every time a new UI Controls is made
contract BearnUIControlPointer is Authorized {
    address public uiControls;

    constructor(address _authorizer) Authorized(_authorizer) {}

    function setUIControls(
        address _uiControls
    ) external isAuthorized(MANAGER_ROLE) {
        uiControls = _uiControls;
    }
}
