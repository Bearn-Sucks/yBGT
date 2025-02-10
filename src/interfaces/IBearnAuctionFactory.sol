// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IBearnAuctionFactory {
    /* ========== STRUCTS ========== */

    enum AuctionType {
        useDefault,
        yBGT,
        wbera
    }

    /* ========== ERRORS ========== */

    error NotAuth();
    error InvalidAuctionType();

    /* ========== EVENTS ========== */

    event DeployedNewAuction(address indexed auction, address indexed want);
    event NewAuctionType(address indexed want, AuctionType newAuctionType);
    event NewDefaultAuctionType(AuctionType newAuctionType);

    function wbera() external view returns (address);

    function yBGT() external view returns (address);

    function bearnVaultFactory() external view returns (address);

    function wantToAuction(
        address want
    ) external view returns (address auction);

    function defaultAuctionType() external view returns (AuctionType);

    function getAuctions() external view returns (address[] memory);

    function getAuctionsLength() external view returns (uint256);

    function getAuction(uint256 index) external view returns (address);

    function wantToAuctionType(
        address want
    ) external view returns (AuctionType);

    function deployAuction(
        address want,
        address receiver,
        address governance
    ) external;

    function kickAuction(address want, uint256 amount) external;

    function setDefaultAuctionType(AuctionType newAuctionType) external;

    function setAuctionType(address want, AuctionType newAuctionType) external;
}
