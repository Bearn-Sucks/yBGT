// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";
import {BearnVaultFactory} from "src/BearnVaultFactory.sol";

/// @title yBGT Fee Module
/// @author Bearn.sucks
/// @notice
///    Contract that calculates how much BearnBGT to mint/redeem to the user.
///    Currently it just uses a simple wrap/redeem fee percentage.
///    The module is swappable so there can be a dynamic fee module in the future.
contract BearnBGTFeeModule is Authorized {
    error RedeemIsPaused();
    error InvalidFee();

    event NewWrapFee(uint256 newWrapFee);
    event NewRedeemFee(uint256 newRedeemFee);
    event NewVaultWrapFee(uint256 newWrapFee);
    event NewVaultRedeemFee(uint256 newRedeemFee);
    event RedeemPaused(bool);

    uint256 public constant BASIS = 10_000;
    BearnVaultFactory public bearnVaultFactory;
    uint256 public wrapFee;
    uint256 public redeemFee;
    uint256 public vaultWrapFee;
    uint256 public vaultRedeemFee;
    bool public redeemPaused;

    constructor(
        address _authorizer,
        uint256 _wrapFee,
        uint256 _redeemFee,
        uint256 _vaultWrapFee,
        uint256 _vaultRedeemFee,
        bool _redeemPaused
    ) Authorized(_authorizer) {
        wrapFee = _wrapFee;
        emit NewWrapFee(_wrapFee);

        redeemFee = _redeemFee;
        emit NewRedeemFee(_redeemFee);

        vaultWrapFee = _vaultWrapFee;
        emit NewVaultWrapFee(_vaultWrapFee);

        vaultRedeemFee = _vaultRedeemFee;
        emit NewVaultRedeemFee(_vaultRedeemFee);

        redeemPaused = _redeemPaused;
        emit RedeemPaused(_redeemPaused);
    }

    function setBearnFactory(
        address _bearnVaultFactory
    ) external isAuthorized(MANAGER_ROLE) {
        require(address(bearnVaultFactory) == address(0));
        bearnVaultFactory = BearnVaultFactory(_bearnVaultFactory);
    }

    function version() external pure returns (string memory) {
        return "v1.0.0";
    }

    /// @notice Previews how much yBGT a user would get for wrapping BGT
    /// @param to Recipient, can be used for allowlists in the future
    /// @param inputAmount Input amount
    function previewWrap(
        address to,
        uint256 inputAmount
    ) public view returns (uint256 outputAmount, uint256 fee) {
        uint256 _wrapFee = bearnVaultFactory.isBearnVault(to) ||
            to == address(bearnVaultFactory.bearnAuctionFactory())
            ? vaultWrapFee
            : wrapFee;
        fee = (inputAmount * _wrapFee) / BASIS;
        return (inputAmount - fee, fee);
    }

    /// @notice How much yBGT a user would get for wrapping BGT
    /// @dev Writable instead of view to support dynamic fees in the future
    /// @param to Recipient, can be used for allowlists in the future
    /// @param inputAmount Input amount
    function wrap(
        address to,
        uint256 inputAmount
    ) external returns (uint256 outputAmount, uint256 fee) {
        return previewWrap(to, inputAmount);
    }

    /// @notice Previews how much BGT a user would get back for redeeming yBGT
    /// @param to Recipient, can be used for allowlists in the future
    /// @param inputAmount Input amount
    function previewRedeem(
        address to,
        uint256 inputAmount
    ) public view returns (uint256 outputAmount, uint256 fee) {
        require(!redeemPaused, RedeemIsPaused());

        uint256 _redeemFee = bearnVaultFactory.isBearnVault(to) ||
            to == address(bearnVaultFactory.bearnAuctionFactory())
            ? vaultRedeemFee
            : redeemFee;

        fee = (inputAmount * _redeemFee) / BASIS;
        return (inputAmount - fee, fee);
    }

    /// @notice How much BGT a user would get back for redeeming yBGT
    /// @dev Writable instead of view to support dynamic fees in the future
    /// @param to Recipient, can be used for allowlists in the future
    /// @param inputAmount Input amount
    function redeem(
        address to,
        uint256 inputAmount
    ) external returns (uint256 outputAmount, uint256 fee) {
        return previewRedeem(to, inputAmount);
    }

    function setWrapFee(
        uint256 newWrapFee
    ) external isAuthorized(MANAGER_ROLE) {
        require(newWrapFee < BASIS, InvalidFee());

        wrapFee = newWrapFee;
        emit NewWrapFee(newWrapFee);
    }

    function setRedeemFee(
        uint256 newRedeemFee
    ) external isAuthorized(MANAGER_ROLE) {
        require(newRedeemFee < BASIS, InvalidFee());

        redeemFee = newRedeemFee;
        emit NewRedeemFee(newRedeemFee);
    }

    function setVaultWrapFee(
        uint256 newWrapFee
    ) external isAuthorized(MANAGER_ROLE) {
        require(newWrapFee < BASIS, InvalidFee());

        vaultWrapFee = newWrapFee;
        emit NewVaultWrapFee(newWrapFee);
    }

    function setVaultRedeemFee(
        uint256 newRedeemFee
    ) external isAuthorized(MANAGER_ROLE) {
        require(newRedeemFee < BASIS, InvalidFee());

        vaultRedeemFee = newRedeemFee;
        emit NewVaultRedeemFee(newRedeemFee);
    }

    function setRedeemPaused(
        bool newState
    ) external isAuthorized(MANAGER_ROLE) {
        redeemPaused = newState;
        emit RedeemPaused(newState);
    }
}
