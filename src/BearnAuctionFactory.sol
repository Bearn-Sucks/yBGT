// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";
import {AuctionFactory} from "@yearn/tokenized-strategy-periphery/Auctions/AuctionFactory.sol";

import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBearnVaultManager} from "src/interfaces/IBearnVaultManager.sol";
import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";

contract BearnAuctionFactory {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ========== STRUCTS ========== */

    enum AuctionType {
        useDefault,
        yBGT,
        wbera
    }

    /* ========== ERRORS ========== */

    error NotAuth();
    error InvalidAuctionType();
    error AuctionExists();

    /* ========== EVENTS ========== */

    event DeployedNewAuction(address indexed auction, address indexed want);
    event NewAuctionType(address indexed want, AuctionType newAuctionType);
    event NewDefaultAuctionType(AuctionType newAuctionType);

    /* ========== MODIFIERS ========== */

    modifier onlyBearnVaultFactory() {
        _onlyBearnVaultFactory();
        _;
    }

    function _onlyBearnVaultFactory() internal view {
        require(msg.sender == address(bearnVaultFactory), NotAuth());
    }

    modifier onlyBearnVaults() {
        _onlyBearnVaults();
        _;
    }

    function _onlyBearnVaults() internal view {
        require(bearnVaultFactory.isBearnVault(msg.sender), NotAuth());
    }

    modifier onlyBearnVaultManager() {
        _onlyBearnVaultManager();
        _;
    }

    function _onlyBearnVaultManager() internal view {
        require(msg.sender == bearnVaultFactory.bearnVaultManager(), NotAuth());
    }

    /* ========== IMMUTABLES ========== */

    address public immutable wbera;
    address public immutable yBGT;
    IBearnVaultFactory public immutable bearnVaultFactory;
    AuctionFactory public constant yearnAuctionFactory =
        AuctionFactory(0xCfA510188884F199fcC6e750764FAAbE6e56ec40); // Yearn's Auction Factory on Bera

    /* ========== STATES ========== */

    EnumerableSet.AddressSet auctions;
    mapping(address want => address auction) public wantToAuction;
    mapping(address want => AuctionType) internal _wantToAuctionType;
    AuctionType public defaultAuctionType;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _wbera, address _yBGT, address _bearnVaultFactory) {
        wbera = _wbera;
        yBGT = _yBGT;
        bearnVaultFactory = IBearnVaultFactory(_bearnVaultFactory);

        defaultAuctionType = AuctionType.yBGT;

        emit NewDefaultAuctionType(AuctionType.yBGT);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getAuctions() external view returns (address[] memory) {
        return auctions.values();
    }

    function getAuctionsLength() external view returns (uint256) {
        return auctions.length();
    }

    function getAuction(uint256 index) external view returns (address) {
        return auctions.at(index);
    }

    function wantToAuctionType(
        address want
    ) public view returns (AuctionType auctionType) {
        auctionType = _wantToAuctionType[want];
        if (auctionType == AuctionType.useDefault) {
            return defaultAuctionType;
        }
        return auctionType;
    }

    /* ========== START AUCTION ========== */

    function deployAuction(
        address want,
        address receiver,
        address governance
    ) external onlyBearnVaultFactory {
        _deployAuction(want, receiver, governance);
    }

    function _deployAuction(
        address want,
        address receiver,
        address governance
    ) internal {
        require(wantToAuction[want] == address(0), AuctionExists());

        // Initialize with address(this) as governance first so we can enable markets
        Auction _newAuction = Auction(
            yearnAuctionFactory.createNewAuction(
                want,
                receiver,
                address(this),
                1 days,
                1e6
            )
        );

        // Enable markets
        if (want != wbera) {
            _newAuction.enable(wbera);
        }
        if (want != yBGT) {
            _newAuction.enable(yBGT);
        }

        // Pass governance of the new auction
        _newAuction.transferGovernance(governance);
        IBearnVaultManager(governance).registerAuction(address(_newAuction));

        auctions.add(address(_newAuction));

        wantToAuction[want] = address(_newAuction);

        emit DeployedNewAuction(address(_newAuction), want);
    }

    /// @dev Permissioned to prevent DOS attacks
    /// @param want Auction want
    /// @param amount Amount to auction
    function kickAuction(
        address want,
        uint256 amount
    ) external onlyBearnVaults {
        Auction auction = Auction(wantToAuction[want]);

        // Deploy an auction if needed, could happen if BearnAuctionFactory was migrated
        if (address(auction) == address(0)) {
            _deployAuction(
                want,
                msg.sender,
                bearnVaultFactory.bearnVaultManager()
            );
        }

        AuctionType auctionType = wantToAuctionType(want);

        if (auctionType == AuctionType.wbera) {
            // redeem to wbera if needed
            IERC20(yBGT).safeTransferFrom(msg.sender, address(this), amount);
            amount = IBearnBGT(yBGT).redeem(amount);
            IERC20(wbera).safeTransfer(address(auction), amount);
            auction.kick(wbera);
        } else {
            // use yBGT itself otherwise
            IERC20(yBGT).safeTransferFrom(msg.sender, address(auction), amount);
            auction.kick(yBGT);
        }
    }

    /* ========== MANAGEMENT FUNCTIONS ========== */

    function setDefaultAuctionType(
        AuctionType newAuctionType
    ) external onlyBearnVaultManager {
        require(newAuctionType != AuctionType.useDefault, InvalidAuctionType());

        if (defaultAuctionType != newAuctionType) {
            defaultAuctionType = newAuctionType;
            emit NewDefaultAuctionType(newAuctionType);
        }
    }

    function setAuctionType(
        address want,
        AuctionType newAuctionType
    ) external onlyBearnVaultManager {
        if (_wantToAuctionType[want] != newAuctionType) {
            _wantToAuctionType[want] = newAuctionType;
            emit NewAuctionType(want, newAuctionType);
        }
    }
}
