// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";

contract BearnBGT is ERC20, ERC20Permit, AccessControlEnumerable {
    error NoBeraVault();
    error NoBGT();

    bytes32 public constant MANAGEMENT_ROLE = keccak256("MANAGEMENT_ROLE");

    IBeraVaultFactory public beraVaultFactory;
    address public bearnVoter;

    constructor(
        address defaultAdmin
    ) ERC20("Bearn BGT", "yBGT") ERC20Permit("Bearn BGT") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /// @dev Needs to be initialized after deployment due to deployment order
    function initialize(
        address _beraVaultFactory,
        address _bearnVoter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bearnVoter == address(0));
        beraVaultFactory = IBeraVaultFactory(_beraVaultFactory);
        bearnVoter = _bearnVoter;
    }

    /// @notice
    ///   Users can wrap their unclaimed BGT into yBGT
    ///   by first calling setOperator() on Bera's RewardVault,
    ///   which allows yBGT to claim BGT on their behalf
    /// @param stakingToken Staking token for the Bera RewardVautl
    function wrap(address stakingToken) external returns (uint256 amount) {
        // Get Bera Reward Vault
        IBeraVault beraRewardVault = IBeraVault(
            beraVaultFactory.getVault(stakingToken)
        );
        require(address(beraRewardVault) != address(0), NoBeraVault());

        // Get BGT from the Bera Reward Vault to Bearn Voter
        // This should revert if setOperator() isn't already called beforehand
        // We implicitly trust the amount returned by getReward since we've already confirmed it's a Bera Vault
        amount = IBeraVault(beraRewardVault).getReward(msg.sender, bearnVoter);

        if (amount > 0) {
            _mint(msg.sender, amount);
        }

        return amount;
    }

    /// @notice Allow users to redeem yBGT back into BGT
    /// @param amount Redeem amount
    function redeem(uint256 amount) external returns (uint256 outputAmount) {
        // @TODO Redemption module and decide where the fees go (treasury, other stakers, etc.)
    }

    function previewRedeem(
        uint256 amount
    ) public view returns (uint256 outputAmount) {}
}
