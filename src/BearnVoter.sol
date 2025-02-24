// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

import {IBGT} from "@berachain/contracts/pol/BGT.sol";
import {WBERA} from "@berachain/contracts/WBERA.sol";

import {Authorized} from "@bearn/governance/contracts/Authorized.sol";

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";

import {BearnExecutor} from "src/bases/BearnExecutor.sol";

/// @title BearnVoter
/// @author Bearn.sucks
/// @notice
///   Contract that holds the BGT backing yBGT and also votes with those BGT.
contract BearnVoter is Authorized, BearnExecutor {
    /* ========== ERRORS ========== */

    error NotVoterManager();

    /* ========== EVENTS ========== */

    event NewTreasury(address indexed newTreasury);
    event NewVoterManager(address indexed newVoterManager);

    /// @notice Timelock
    bytes32 public immutable TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    /// @notice Redeem module
    bytes32 public immutable REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    IBGT public immutable bgt;
    WBERA public immutable wbera;
    IGovernor public immutable beraGovernance;
    address public voterManager;
    address public treasury;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _authorizer,
        address _bgt,
        address _wbera,
        address _beraGovernance,
        address _treasury,
        address _voterManager
    ) Authorized(_authorizer) {
        bgt = IBGT(_bgt);
        wbera = WBERA(payable(_wbera));
        beraGovernance = IGovernor(_beraGovernance);
        treasury = _treasury;
        voterManager = _voterManager;

        emit NewTreasury(_treasury);

        /// @dev
        ///     Don't froget to grant the following role pairs after deployment
        ///     REDEEMER_ROLE to yBGT
    }

    /* ========== MANAGER ACTIONS ========== */

    function setTreasury(
        address _treasury
    ) external isAuthorized(MANAGER_ROLE) {
        treasury = _treasury;

        emit NewTreasury(_treasury);
    }

    function setVoterManager(
        address _voterManager
    ) external hasRole(TIMELOCK_ROLE) {
        voterManager = _voterManager;

        emit NewVoterManager(_voterManager);
    }

    /// @notice Makes it so the Manager can vote, propose, boost, drop boost, etc.
    /// @dev
    ///     This allows the Voter contract to be immutable while being able to respond to Berachain
    ///     protocol changes by upgrading BearnVoterManger if needed
    /// @param to Tx destination
    /// @param value Tx value
    /// @param data Tx data
    /// @param operation Call or delegate call
    /// @param allowFailure Allow failure or revert
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bool allowFailure
    ) public payable returns (bool success, bytes memory _returndata) {
        require(msg.sender == voterManager, NotVoterManager());
        return _execute(to, value, data, operation, allowFailure);
    }

    /* ========== REDEEMING ========== */

    function redeem(
        address to,
        uint256 amount
    ) external hasRole(REDEEMER_ROLE) {
        // wrap BERA to avoid any potential trouble with sending native BERA
        // BERA is warpped to wBERA in the receive() function
        bgt.redeem(address(this), amount);
        wbera.transfer(to, amount);
    }

    receive() external payable {
        wbera.deposit{value: msg.value}();
    }
}
