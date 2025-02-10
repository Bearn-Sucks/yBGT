// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";

import {BearnVault} from "src/BearnVault.sol";
import {BearnCompoundingVault} from "src/BearnCompoundingVault.sol";
import {BearnBGTEarnerVault} from "src/BearnBGTEarnerVault.sol";

import {IBearnVaultManager} from "src/interfaces/IBearnVaultManager.sol";
import {IBearnAuctionFactory} from "src/interfaces/IBearnAuctionFactory.sol";
import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnCompoundingVault} from "src/interfaces/IBearnCompoundingVault.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BearnVaultFactory {
    /* ========== ERRORS ========== */

    error NotInitialized();
    error NoBeraVault();
    error NotVaultManager();

    /* ========== EVENTS ========== */

    event NewVaultManager(address newVaultManager);
    event NewAuctionFactory(address newAuctionFactory);
    event NewVaults(
        address indexed stakingToken,
        address compoundingVault,
        address yBGTVault
    );

    /* ========== MODIFIERS ========== */

    modifier onlyManager() {
        _onlyManager();
        _;
    }

    function _onlyManager() internal view {
        require(msg.sender == address(bearnVaultManager), NotVaultManager());
    }

    /* ========== IMMUTABLES ========== */

    IBeraVaultFactory public immutable beraVaultFactory;

    address public immutable keeper; // yearn permissionless keeper
    ERC20 public immutable yBGT;

    /* ========== STATES ========== */

    IBearnVaultManager public bearnVaultManager;
    IBearnAuctionFactory public bearnAuctionFactory;

    mapping(address stakingToken => address) public stakingToCompoundingVaults;
    mapping(address stakingToken => address) public stakingToBGTEarnerVaults;
    mapping(address bearnVaults => bool) public isBearnVault;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _bearnVaultManager,
        address _beraVaultFactory,
        address _yBGT,
        address _keeper
    ) {
        bearnVaultManager = IBearnVaultManager(_bearnVaultManager);
        beraVaultFactory = IBeraVaultFactory(_beraVaultFactory);
        yBGT = ERC20(_yBGT);
        keeper = _keeper;
    }

    function setVaultManager(
        address _newBearnVaultManager
    ) external onlyManager {
        if (address(bearnVaultManager) != _newBearnVaultManager) {
            bearnVaultManager = IBearnVaultManager(_newBearnVaultManager);

            emit NewVaultManager(_newBearnVaultManager);
        }
    }

    function setAuctionFactory(
        address _newAuctionFactory
    ) external onlyManager {
        if (address(bearnAuctionFactory) != _newAuctionFactory) {
            bearnAuctionFactory = IBearnAuctionFactory(_newAuctionFactory);

            emit NewAuctionFactory(_newAuctionFactory);
        }
    }

    function createVaults(
        address stakingToken
    ) external returns (address compoundingVault, address yBGTVault) {
        require(address(yBGT) != address(0), NotInitialized());
        require(address(bearnAuctionFactory) != address(0), NotInitialized());

        // Check if BeraVault exists
        address beraVault = beraVaultFactory.getVault(stakingToken);
        require(beraVault != address(0), NoBeraVault());

        // Create the vaults
        compoundingVault = address(
            new BearnCompoundingVault(
                string.concat(
                    "Bearn ",
                    ERC20(stakingToken).symbol(),
                    " Compounding Vault"
                ),
                stakingToken,
                beraVault,
                address(yBGT)
            )
        );
        yBGTVault = address(
            new BearnBGTEarnerVault(
                string.concat(
                    "Bearn ",
                    ERC20(stakingToken).symbol(),
                    " yBGT Vault"
                ),
                stakingToken,
                beraVault,
                address(yBGT)
            )
        );

        // Deploy Auction
        bearnAuctionFactory.deployAuction(
            stakingToken,
            compoundingVault,
            address(bearnVaultManager)
        );

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
        stakingToCompoundingVaults[stakingToken] = compoundingVault;
        stakingToBGTEarnerVaults[stakingToken] = yBGTVault;
        isBearnVault[compoundingVault] = true;
        isBearnVault[yBGTVault] = true;

        emit NewVaults(stakingToken, compoundingVault, yBGTVault);
    }
}
