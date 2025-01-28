// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {Ownable} from "@openzeppelin/contracts/Access/Ownable.sol";

import {IBearnVault} from "src/interfaces/IBearnVault.sol";

/**
 * @title BearnVaultCompounder
 * @author Bearn
 * @notice
 *  BearnVaultCompounder holds dutch auction to auction off BERA or yBRT (tbd)
 *  in return for help compounding each BearnVault.
 */
contract BearnVaultCompounder is Ownable {
    /* ========== EVENTS ========== */
    event SetDefaultStartingPrice(uint256 oldPrice, uint256 newPrice);
    event SetDefaultAuctionSlope(uint256 oldSlope, uint256 newSlope);

    event SetStartingPrice(
        address indexed bearnVault,
        uint256 oldPrice,
        uint256 newPrice
    );
    event SetAuctionSlope(
        address indexed bearnVault,
        uint256 oldSlope,
        uint256 newSlope
    );

    /// @notice The last time each vault is compounded
    mapping(address bearnVault => uint256) public lastCompounded;

    /// @notice Default starting price for each dutch auction
    uint256 public defaultStartingPrice;
    // @notice Used to override specific vaults, uint256.max stands for using the default price
    mapping(address bearnVault => uint256) internal _startingPrices;

    /// @notice Default rate of price decrease for each dutch auction
    uint256 public defaultAuctionSlope;
    /// @notice Used to override specific vaults, uint256.max stands for using the default slope
    mapping(address bearnVault => uint256) internal _auctionSlopes;

    constructor() {}

    function registerNewVault(
        address bearnVault,
        uint256 _startingPrice,
        uint256 _auctionSlope
    ) external {
        emit SetStartingPrice(bearnVault, 0, _startingPrice);
        emit SetAuctionSlope(bearnVault, 0, _auctionSlope);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Returns the current auction rate being used for each vault
    function auctionSlope(address bearnVault) public view returns (uint256) {
        uint256 _auctionSlope = _auctionSlopes[bearnVault];
        if (_auctionSlope == type(uint256).max) {
            _auctionSlope = defaultAuctionSlope;
        }

        return _auctionSlope;
    }

    /// @notice Returns the current starting price being used for each vault
    function startingPrice(address bearnVault) public view returns (uint256) {
        uint256 __auctionStartPrice = _startingPrices[bearnVault];
        if (__auctionStartPrice == type(uint256).max) {
            __auctionStartPrice = defaultStartingPrice;
        }

        return __auctionStartPrice;
    }

    /* ========== OWNER ACTIONS ========== */

    /// @notice Sets the current starting price being used for each vault
    /// @param bearnVault Bearn vault address, address(0) for default
    /// @param newPrice New Price
    function setStartingPrice(
        address bearnVault,
        uint256 newPrice
    ) external onlyOwner {
        if (bearnVault == address(0)) {
            uint256 oldDefaultPrice = defaultStartingPrice;
            emit SetDefaultStartingPrice(oldDefaultPrice, newPrice);
            return;
        }

        uint256 oldPrice = startingPrice(bearnVault);
        _startingPrices[bearnVault] = newPrice;

        emit SetStartingPrice(bearnVault, oldPrice, newPrice);
    }

    /// @notice Sets the current starting slope being used for each vault
    /// @param bearnVault Bearn vault address, address(0) for default
    /// @param newSlope New Price
    function setAuctionSlope(
        address bearnVault,
        uint256 newSlope
    ) external onlyOwner {
        if (bearnVault == address(0)) {
            uint256 oldDefaultSlope = defaultAuctionSlope;
            emit SetDefaultStartingPrice(oldDefaultSlope, newSlope);
            return;
        }

        uint256 oldSlope = auctionSlope(bearnVault);
        _auctionSlopes[bearnVault] = newSlope;

        emit SetStartingPrice(bearnVault, oldSlope, newSlope);
    }
}
