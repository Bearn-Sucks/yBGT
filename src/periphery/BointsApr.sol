// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";
import {IBearnVault} from "../interfaces/IBearnVault.sol";
import {BearnUIControlCentre} from "./BearnUIControlCentre.sol";

contract BointsApr is Authorized {
    event BointsAprUpdated(
        uint256 bointsWeeklyRate,
        uint256 yBgtStakerRate,
        uint256 yBgtLPRate,
        uint256 yBeraRate,
        uint256 yHoneyRate
    );
    BearnUIControlCentre public uiController =
        BearnUIControlCentre(0xD36e0A4Ae7258Dd1FfE0D7f9f851461369a1AA0E);

    address public constant yBGT = 0x7e768f47dfDD5DAe874Aac233f1Bc5817137E453;

    address public constant styBGT = 0x6f8cEAF347dA79287e49A5C9F0a03b20BDFCB7D3;

    address public constant WBERA = 0x6969696969696969696969696969696969696969;

    address public constant honey = 0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce;

    address public constant styBERA =
        0xCD0A794A2FfF32e21Dc4fE3081909Ad7e4B55a35;

    address public constant styHoney =
        0x99d6A0FB9420F3995fD07dCc36AC827a8E146cf9;

    address public constant yBGT_yBERA_COMPOUNDER =
        0x6e36B83bb32B5C6D2B3874A5259a8A9d9b378F36;

    address public constant yBGT_yBERA_EARNER =
        0x0d3b8E9628Ddad47f0c6b437B4Aa2a3Fda9C0b76;

    uint256 public constant TOTAL_SUPPLY = 100_000_000;

    uint256 public bointsWeeklyRate;

    uint256 public yBgtStakerRate;

    uint256 public yBgtLPRate;

    uint256 public yBeraRate;

    uint256 public yHoneyRate;

    constructor(address _authorizer) Authorized(_authorizer) {
        bointsWeeklyRate = 75000;
        yBgtStakerRate = 12500;
        yBgtLPRate = 62500;
        yBeraRate = 20000;
        yHoneyRate = 10000;
    }

    function setBointsRate(
        uint256 _totalRate,
        uint256 _yBgtStakerRate,
        uint256 _yBgtLPRate,
        uint256 _yBeraRate,
        uint256 _yHoneyRate
    ) external isAuthorized(MANAGER_ROLE) {
        bointsWeeklyRate = _totalRate;
        yBgtStakerRate = _yBgtStakerRate;
        yBgtLPRate = _yBgtLPRate;
        yBeraRate = _yBeraRate;
        yHoneyRate = _yHoneyRate;

        emit BointsAprUpdated(
            _totalRate,
            _yBgtStakerRate,
            _yBgtLPRate,
            _yBeraRate,
            _yHoneyRate
        );
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
        uint256 islandPrice = uiController.getStakePrice(
            IBearnVault(yBGT_yBERA_COMPOUNDER).asset()
        );
        uint256 lp_tvl = ((IBearnVault(yBGT_yBERA_COMPOUNDER).totalAssets() +
            IBearnVault(yBGT_yBERA_EARNER).totalAssets()) * islandPrice) / 1e18;
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

    function getYHoneyBointsRate() public view returns (uint256) {
        uint256 honeyPrice = uiController.getStakePrice(honey);
        uint256 styHoneyTVL = (IBearnVault(styHoney).totalAssets() *
            honeyPrice) / 1e18;
        uint256 annualizedRate = yHoneyRate * 1e18 * 52;
        return (annualizedRate * 1e18) / styHoneyTVL;
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

    function getHoneyBointsApr(uint256 fdv) public view returns (uint256) {
        return (getYHoneyBointsRate() * fdv) / TOTAL_SUPPLY;
    }
}
