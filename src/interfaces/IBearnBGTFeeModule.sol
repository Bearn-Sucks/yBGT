// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnBGTFeeModule {
    error RedeemIsPaused();
    error InvalidFee();

    event NewWrapFee(uint256 newWrapFee);
    event NewRedeemFee(uint256 newRedeemFee);
    event NewVaultWrapFee(uint256 newWrapFee);
    event NewVaultRedeemFee(uint256 newRedeemFee);
    event RedeemPaused(bool);

    function BASIS() external pure returns (uint256);

    function bearnVaultFactory() external view returns (address);

    function bearnAuctionFactory() external view returns (address);

    function wrapFee() external view returns (uint256);

    function redeemFee() external view returns (uint256);

    function vaultWrapFee() external view returns (uint256);

    function vaultRedeemFee() external view returns (uint256);

    function redeemPaused() external view returns (bool);

    function setBearnFactories(
        address _bearnVaultFactory,
        address _bearnAuctionFactory
    ) external;

    function version() external pure returns (string memory);

    function previewWrap(
        address to,
        uint256 inputAmount
    ) external view returns (uint256 outputAmount, uint256 fee);

    function wrap(
        address to,
        uint256 inputAmount
    ) external returns (uint256 outputAmount, uint256 fee);

    function redeem(
        address to,
        uint256 inputAmount
    ) external returns (uint256 outputAmount, uint256 fee);

    function previewRedeem(
        address to,
        uint256 inputAmount
    ) external view returns (uint256 outputAmount, uint256 fee);

    function setWrapFee(uint256 newWrapFee) external;

    function setRedeemFee(uint256 newRedeemFee) external;

    function setVaultWrapFee(uint256 newWrapFee) external;

    function setVaultRedeemFee(uint256 newRedeemFee) external;
}
