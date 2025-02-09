// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IRewardVaultFactory as IBeraVaultFactory} from "@berachain/contracts/pol/interfaces/IRewardVaultFactory.sol";
import {IBearnBGTFeeModule} from "src/interfaces/IBearnBGTFeeModule.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";

contract BearnBGT is ERC20, ERC20Permit, AccessControlEnumerable {
    error NoBeraVault();
    error NoBGT();

    event NewFeeModule(address newFeeModule);
    event NewFeeRecipient(address newFeeRecipient);

    bytes32 public constant MANAGEMENT_ROLE = keccak256("MANAGEMENT_ROLE");

    IBeraVaultFactory public immutable beraVaultFactory;
    IBearnVoter public immutable bearnVoter;

    IBearnBGTFeeModule public feeModule;
    address public feeRecipient;

    constructor(
        address defaultAdmin,
        address _beraVaultFactory,
        address _bearnVoter,
        address _feeModule
    ) ERC20("Bearn BGT", "yBGT") ERC20Permit("Bearn BGT") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MANAGEMENT_ROLE, defaultAdmin);

        beraVaultFactory = IBeraVaultFactory(_beraVaultFactory);
        bearnVoter = IBearnVoter(_bearnVoter);

        feeModule = IBearnBGTFeeModule(_feeModule);
        emit NewFeeModule(_feeModule);

        feeRecipient = defaultAdmin;
        emit NewFeeRecipient(defaultAdmin);
    }

    /// @notice
    ///   Users can wrap their unclaimed BGT into yBGT
    ///   by first calling setOperator() on Bera's RewardVault,
    ///   which allows yBGT to claim BGT on their behalf
    /// @param stakingToken Staking token for the Bera RewardVautl
    function wrap(
        address stakingToken
    ) external returns (uint256 outputAmount) {
        // Get Bera Reward Vault
        IBeraVault beraRewardVault = IBeraVault(
            beraVaultFactory.getVault(stakingToken)
        );
        require(address(beraRewardVault) != address(0), NoBeraVault());

        // Get BGT from the Bera Reward Vault to Bearn Voter
        // This should revert if setOperator() isn't already called beforehand
        // We implicitly trust the amount returned by getReward since we've already confirmed it's a Bera Vault
        outputAmount = IBeraVault(beraRewardVault).getReward(
            msg.sender,
            address(bearnVoter)
        );

        uint256 feeAmount;
        (outputAmount, feeAmount) = feeModule.wrap(msg.sender, outputAmount);

        if (outputAmount > 0) {
            _mint(msg.sender, outputAmount);
        }
        if (feeAmount > 0) {
            _mint(feeRecipient, outputAmount);
        }

        return outputAmount;
    }

    /// @notice Allow users to redeem yBGT back into BGT
    /// @param amount Redeem amount
    /// @dev Redeem can be paused by making Fee Module revert on redeeming
    function redeem(uint256 amount) external returns (uint256 outputAmount) {
        uint256 fee;
        (outputAmount, fee) = feeModule.redeem(msg.sender, amount);

        // burn and redeem to msg.sender
        if (outputAmount > 0) {
            _burn(msg.sender, outputAmount);
            bearnVoter.redeem(msg.sender, outputAmount);
        }

        // transfer fees to fee recipient
        if (fee > 0) {
            _transfer(msg.sender, feeRecipient, fee);
        }

        return outputAmount;
    }

    function previewWrap(
        address to,
        uint256 inputAmount
    ) external view returns (uint256 outputAmount) {
        (outputAmount, ) = feeModule.previewWrap(to, inputAmount);

        return outputAmount;
    }

    function previewRedeem(
        address to,
        uint256 inputAmount
    ) public view returns (uint256 outputAmount) {
        (outputAmount, ) = feeModule.previewRedeem(to, inputAmount);

        return outputAmount;
    }

    function setFeeModule(
        address newFeeModule
    ) external onlyRole(MANAGEMENT_ROLE) {
        feeModule = IBearnBGTFeeModule(newFeeModule);

        emit NewFeeModule(newFeeModule);
    }

    function setFeeRecipient(
        address newFeeRecipient
    ) external onlyRole(MANAGEMENT_ROLE) {
        feeRecipient = newFeeRecipient;

        emit NewFeeRecipient(newFeeRecipient);
    }
}
