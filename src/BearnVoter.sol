// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

import {IBGT} from "@berachain/contracts/pol/BGT.sol";
import {WBERA} from "@berachain/contracts/WBERA.sol";

import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";

import {BearnExecutor} from "src/bases/BearnExecutor.sol";

/// @title BearnVoter
/// @author Bearn.sucks
/// @notice
///   Contract that holds the BGT backing yBGT and also votes with those BGT.
contract BearnVoter is AccessControlEnumerable, BearnExecutor {
    /* ========== EVENTS ========== */

    event NewTreasury(address indexed newTreasury);

    /// @notice In charge of voting
    bytes32 public immutable MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// @notice Redeem module
    bytes32 public immutable REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    IBGT public immutable bgt;
    WBERA public immutable wbera;
    IGovernor public immutable beraGovernance;
    address public treasury;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _bgt,
        address _wbera,
        address _beraGovernance,
        address _treasury
    ) {
        bgt = IBGT(_bgt);
        wbera = WBERA(payable(_wbera));
        beraGovernance = IGovernor(_beraGovernance);
        treasury = _treasury;
        emit NewTreasury(_treasury);

        /// @dev
        ///     Don't froget to grant the following role pairs after deployment
        ///     REDEEMER_ROLE to yBGT
        ///     MANAGER_ROLE to BearnVoteManager
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== MANAGER ACTIONS ========== */

    function setTreasury(
        address _treasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = _treasury;
        emit NewTreasury(_treasury);
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
    )
        public
        payable
        onlyRole(MANAGER_ROLE)
        returns (bool success, bytes memory _returndata)
    {
        return _execute(to, value, data, operation, allowFailure);
    }

    /* ========== REDEEMING ========== */

    function redeem(
        address to,
        uint256 amount
    ) external onlyRole(REDEEMER_ROLE) {
        // wrap BERA to avoid any potential trouble with sending native BERA
        // BERA is warpped to wBERA in the receive() function
        bgt.redeem(address(this), amount);
        wbera.transfer(to, amount);
    }

    receive() external payable {
        wbera.deposit{value: msg.value}();
    }
}
