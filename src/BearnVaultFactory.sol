// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {BearnVault} from "src/BearnVault.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {BearnBGTEarnerVault} from "src/BearnBGTEarnerVault.sol";

import {BearnCompoundingVaultDeployer} from "src/libraries/BearnCompoundingVaultDeployer.sol";
import {BearnBGTEarnerVaultDeployer} from "src/libraries/BearnBGTEarnerVaultDeployer.sol";

import {IBearnVaultManager} from "src/interfaces/IBearnVaultManager.sol";
import {IBearnAuctionFactory} from "src/interfaces/IBearnAuctionFactory.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnCompoundingVault} from "src/interfaces/IBearnCompoundingVault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BearnVaultFactory is Authorized {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ========== ERRORS ========== */

    error NotInitialized();
    error NoBeraVault();
    error AlreadyExists();

    /* ========== EVENTS ========== */

    event NewVaultManager(address newVaultManager);
    event NewAuctionFactory(address newAuctionFactory);
    event NewVaults(
        address indexed stakingToken,
        address compoundingVault,
        address yBGTVault
    );

    /* ========== IMMUTABLES ========== */

    IBeraVaultFactory public immutable beraVaultFactory;

    address public immutable keeper; // yearn permissionless keeper
    ERC20 public immutable yBGT;

    /* ========== STATES ========== */

    IBearnVaultManager public bearnVaultManager;
    IBearnAuctionFactory public bearnAuctionFactory;

    EnumerableSet.AddressSet compoundingVaults;
    EnumerableSet.AddressSet bgtEarnerVaults;
    mapping(address stakingToken => address) public stakingToCompoundingVaults;
    mapping(address stakingToken => address) public stakingToBGTEarnerVaults;
    mapping(address bearnVaults => bool) public isBearnVault;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _authorizer,
        address _beraVaultFactory,
        address _yBGT,
        address _keeper
    ) Authorized(_authorizer) {
        beraVaultFactory = IBeraVaultFactory(_beraVaultFactory);
        yBGT = ERC20(_yBGT);
        keeper = _keeper;
    }

    function getAllCompoundingVaultsLength() external view returns (uint256) {
        return compoundingVaults.length();
    }

    function getCompoundingVault(
        uint256 index
    ) external view returns (address) {
        return compoundingVaults.at(index);
    }

    function getAllCompoundingVaults()
        external
        view
        returns (address[] memory)
    {
        return compoundingVaults.values();
    }

    function getAllBgtEarnerVaultsLength() external view returns (uint256) {
        return bgtEarnerVaults.length();
    }

    function getBgtEarnerVault(uint256 index) external view returns (address) {
        return bgtEarnerVaults.at(index);
    }

    function getAllBgtEarnerVaults() external view returns (address[] memory) {
        return bgtEarnerVaults.values();
    }

    function setVaultManager(
        address _newBearnVaultManager
    ) external isAuthorized(MANAGER_ROLE) {
        if (address(bearnVaultManager) != _newBearnVaultManager) {
            bearnVaultManager = IBearnVaultManager(_newBearnVaultManager);

            emit NewVaultManager(_newBearnVaultManager);
        }
    }

    function setAuctionFactory(
        address _newAuctionFactory
    ) external isAuthorized(MANAGER_ROLE) {
        if (address(bearnAuctionFactory) != _newAuctionFactory) {
            bearnAuctionFactory = IBearnAuctionFactory(_newAuctionFactory);

            emit NewAuctionFactory(_newAuctionFactory);
        }
    }

    function createVaults(
        address stakingToken
    ) external returns (address compoundingVault, address yBGTVault) {
        require(address(bearnVaultManager) != address(0), NotInitialized());
        require(address(bearnAuctionFactory) != address(0), NotInitialized());

        // Check if BeraVault exists
        address beraVault = beraVaultFactory.getVault(stakingToken);
        require(beraVault != address(0), NoBeraVault());

        // Check if BearnVault already exists
        require(
            stakingToCompoundingVaults[stakingToken] == address(0),
            AlreadyExists()
        );

        // Create the vaults
        compoundingVault = BearnCompoundingVaultDeployer.deployVault(
            stakingToken,
            beraVault,
            address(yBGT)
        );
        yBGTVault = BearnBGTEarnerVaultDeployer.deployVault(
            stakingToken,
            beraVault,
            address(yBGT)
        );

        // Deploy Auction
        bearnAuctionFactory.deployAuction(
            stakingToken,
            compoundingVault,
            address(bearnVaultManager)
        );

        // Set compound time
        IBearnVault(compoundingVault).setProfitMaxUnlockTime(2 days);
        IBearnVault(yBGTVault).setProfitMaxUnlockTime(2 days);

        // Transfer keepers
        IBearnVault(compoundingVault).setKeeper(keeper);
        IBearnVault(yBGTVault).setKeeper(keeper);

        // Transfer managements
        IBearnVault(compoundingVault).setPendingManagement(
            address(bearnVaultManager)
        );
        IBearnVault(yBGTVault).setPendingManagement(address(bearnVaultManager));
        bearnVaultManager.registerVault(compoundingVault);
        bearnVaultManager.registerVault(yBGTVault);

        // Record the vaults
        compoundingVaults.add(compoundingVault);
        bgtEarnerVaults.add(yBGTVault);
        stakingToCompoundingVaults[stakingToken] = compoundingVault;
        stakingToBGTEarnerVaults[stakingToken] = yBGTVault;
        isBearnVault[compoundingVault] = true;
        isBearnVault[yBGTVault] = true;

        emit NewVaults(stakingToken, compoundingVault, yBGTVault);
    }
}
