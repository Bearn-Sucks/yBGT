// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";
import {IBearnVault} from "../interfaces/IBearnVault.sol";
import {BearnUIControlCentre} from "./BearnUIControlCentre.sol";

contract BointsApr is Authorized {
    BearnUIControlCentre public uiController =
        BearnUIControlCentre(0xD36e0A4Ae7258Dd1FfE0D7f9f851461369a1AA0E);

    address public constant yBGT = 0x7e768f47dfDD5DAe874Aac233f1Bc5817137E453;

    address public constant styBGT = 0x6f8cEAF347dA79287e49A5C9F0a03b20BDFCB7D3;

    address public constant WBERA = 0x6969696969696969696969696969696969696969;

    address public constant styBERA =
        0x982940eBfC5caa2F5b5a82AAc2Dfa99F18BB7dA4;

    address public constant yBGT_yBERA_ISLAND =
        0x5347e5133b22A680Ee94b7e62803E848F8d8C92e;

    uint256 public constant TOTAL_SUPPLY = 100_000_000;

    uint256 public bointsWeeklyRate;

    uint256 public yBgtStakerRate;

    uint256 public yBgtLPRate;

    uint256 public yBeraRate;

    constructor(address _authorizer) Authorized(_authorizer) {
        bointsWeeklyRate = 75000;
        yBgtStakerRate = 37500;
        yBgtLPRate = 37500;
        yBeraRate = 0;
    }

    function setBointsRate(
        uint256 _totalRate,
        uint256 _yBgtStakerRate,
        uint256 _yBgtLPRate,
        uint256 _yBeraRate
    ) external isAuthorized(MANAGER_ROLE) {
        bointsWeeklyRate = _totalRate;
        yBgtStakerRate = _yBgtStakerRate;
        yBgtLPRate = _yBgtLPRate;
        yBeraRate = _yBeraRate;
    }

    function setUiController(
        address _uiController
    ) external isAuthorized(MANAGER_ROLE) {
        uiController = BearnUIControlCentre(_uiController);
    }

    function getStakedBointsRate() public view returns (uint256) {
        uint256 yBGTPrice = uiController.getStakePrice(yBGT);
        uint256 staked_tvl = (IERC20(styBGT).totalSupply() * yBGTPrice) / 1e18;
        uint256 annualizedRate = yBgtStakerRate * 1e18 * 52;
        return (annualizedRate * 1e18) / staked_tvl;
    }

    function getLPBointsRate() public view returns (uint256) {
        uint256 islandPrice = uiController.getStakePrice(yBGT_yBERA_ISLAND);
        uint256 lp_tvl = (IERC20(yBGT_yBERA_ISLAND).totalSupply() *
            islandPrice) / 1e18;
        uint256 annualizedRate = yBgtLPRate * 1e18 * 52;
        return (annualizedRate * 1e18) / lp_tvl;
    }

    function getYBeraBointsRate() public view returns (uint256) {
        uint256 beraPrice = uiController.getStakePrice(WBERA);
        uint256 styBeraTVL = (IBearnVault(styBERA).totalAssets() * beraPrice) /
            1e18;
        uint256 annualizedRate = yBeraRate * 1e18 * 52;
        return (annualizedRate * 1e18) / styBeraTVL;
    }

    function getStakedBointsApr(uint256 fdv) public view returns (uint256) {
        return (getStakedBointsRate() * fdv) / TOTAL_SUPPLY;
    }

    function getLPBointsApr(uint256 fdv) public view returns (uint256) {
        return (getLPBointsRate() * fdv) / TOTAL_SUPPLY;
    }

    function getYBeraBointsApr(uint256 fdv) public view returns (uint256) {
        return (getYBeraBointsRate() * fdv) / TOTAL_SUPPLY;
    }
}
