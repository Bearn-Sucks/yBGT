// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";

import {BearnAuthorizer} from "@bearn/governance/contracts/BearnAuthorizer.sol";
import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";

import {BearnExecutor} from "src/bases/BearnExecutor.sol";

/// @title BearnVaultManager
/// @author Bearn.sucks
/// @notice Used to manage vaults, makes it easier to transfer ownership of all vaults if needed
contract BearnVaultManager is BearnExecutor, Authorized {
    /* ========== ERRORS ========== */

    error NotFactory();
    error MaxFee();

    /* ========== Events ========== */

    event UpdateEmergencyAdmin(address indexed newEmergencyAdmin);
    event UpdatePerformanceFee(uint256 newPerformanceFee);

    address public immutable bearnVaultFactory;
    address public immutable bearnVoter;
    address public emergencyAdmin;

    uint16 public performanceFee;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _authorizer,
        address _emergencyAdmin,
        address _bearnVaultFactory,
        address _bearnVoter
    ) Authorized(_authorizer) {
        emergencyAdmin = _emergencyAdmin;
        performanceFee = 500; // 5%
        bearnVaultFactory = _bearnVaultFactory;
        bearnVoter = _bearnVoter;

        emit UpdateEmergencyAdmin(_emergencyAdmin);
        emit UpdatePerformanceFee(500);
    }

    function registerVault(address bearnVault) external {
        require(
            msg.sender == bearnVaultFactory ||
                BearnAuthorizer(AUTHORIZER).isAuthorized(
                    MANAGER_ROLE,
                    msg.sender
                ),
            NotFactory()
        );

        IBearnVault(bearnVault).acceptManagement();
        address treasury = IBearnVoter(bearnVoter).treasury();
        _syncVaultSettings(
            bearnVault,
            treasury,
            performanceFee,
            emergencyAdmin
        );
    }

    function syncVaultSettings(
        address[] calldata bearnVaults
    ) external isAuthorized(MANAGER_ROLE) {
        address _treasury = IBearnVoter(bearnVoter).treasury();
        uint16 _performanceFee = performanceFee;
        address _emergencyAdmin = emergencyAdmin;

        uint256 length = bearnVaults.length;

        for (uint256 i; i < length; i++) {
            _syncVaultSettings(
                bearnVaults[i],
                _treasury,
                _performanceFee,
                _emergencyAdmin
            );
        }
    }

    function _syncVaultSettings(
        address _bearnVault,
        address _treasury,
        uint16 _performanceFee,
        address _emergencyAdmin
    ) internal {
        IBearnVault(_bearnVault).setPerformanceFeeRecipient(_treasury);
        IBearnVault(_bearnVault).setPerformanceFee(_performanceFee);
        IBearnVault(_bearnVault).setEmergencyAdmin(_emergencyAdmin);
    }

    function registerAuction(address auction) external {
        require(
            msg.sender ==
                IBearnVaultFactory(bearnVaultFactory).bearnAuctionFactory() ||
                BearnAuthorizer(AUTHORIZER).isAuthorized(
                    MANAGER_ROLE,
                    msg.sender
                ),
            NotFactory()
        );

        Auction(auction).acceptGovernance();
    }

    /// @dev This function only changes the emergency admin for new vaults,
    /// txs should be queued via syncVaultSettings() to update existing vaults
    /// @param _emergencyAdmin New emergency admin
    function setEmergencyAdmin(
        address _emergencyAdmin
    ) external isAuthorized(MANAGER_ROLE) {
        emergencyAdmin = _emergencyAdmin;
        emit UpdateEmergencyAdmin(_emergencyAdmin);
    }

    /// @dev This function only changes the performance fee for new vaults,
    /// txs should be queued via syncVaultSettings() to update existing vaults
    /// @param _performanceFee New performance fee
    function setPerformanceFee(
        uint256 _performanceFee
    ) external isAuthorized(MANAGER_ROLE) {
        require(_performanceFee < 50_000, MaxFee()); // MAX_FEE of vaults
        performanceFee = uint16(_performanceFee);
        emit UpdatePerformanceFee(_performanceFee);
    }

    /// @notice Makes it so the Manager can do arbitrary calls
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
        isAuthorized(MANAGER_ROLE)
        returns (bool success, bytes memory _returndata)
    {
        return _execute(to, value, data, operation, allowFailure);
    }
}
