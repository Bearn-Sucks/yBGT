// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/// @title yBGT Fee Module
/// @author Bearn.sucks
/// @notice
///    Contract that calculates how much BearnBGT to mint/redeem to the user.
///    Currently it just uses a simple wrap/redeem fee percentage.
///    The module is swappable so there can be a dynamic fee module in the future.
contract BearnBGTFeeModule is AccessControlEnumerable {
    error RedeemIsPaused();
    error InvalidFee();

    event NewWrapFee(uint256 newWrapFee);
    event NewRedeemFee(uint256 newRedeemFee);
    event RedeemPaused(bool);

    uint256 public immutable BASIS;
    uint256 public wrapFee;
    uint256 public redeemFee;
    bool public redeemPaused;

    constructor(uint256 _wrapFee, uint256 _redeemFee, bool _redeemPaused) {
        BASIS = 10_000;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        wrapFee = _wrapFee;
        emit NewWrapFee(_wrapFee);

        redeemFee = _redeemFee;
        emit NewRedeemFee(_redeemFee);

        redeemPaused = _redeemPaused;
        emit RedeemPaused(_redeemPaused);
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
        fee = (inputAmount * wrapFee) / BASIS;
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
        fee = (inputAmount * redeemFee) / BASIS;
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newWrapFee < BASIS, InvalidFee());

        wrapFee = newWrapFee;
        emit NewWrapFee(newWrapFee);
    }

    function setRedeemFee(
        uint256 newRedeemFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newRedeemFee < BASIS, InvalidFee());

        redeemFee = newRedeemFee;
        emit NewRedeemFee(newRedeemFee);
    }
}
