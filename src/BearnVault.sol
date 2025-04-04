// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/TokenizedStaker.sol";

import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";

abstract contract BearnVault is TokenizedStaker {
    using SafeERC20 for IERC20;

    IBearnVaultFactory public immutable bearnVaultFactory;
    IBeraVault public immutable beraVault;
    IBearnBGT public immutable yBGT;
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        address _asset,
        address _beraVault,
        address _yBGT
    ) TokenizedStaker(_asset, _name) {
        symbol = _symbol;
        bearnVaultFactory = IBearnVaultFactory(msg.sender);
        beraVault = IBeraVault(_beraVault);
        yBGT = IBearnBGT(_yBGT);

        // set up approvals
        IERC20(_asset).forceApprove(address(beraVault), type(uint256).max); // force approve is the new safeApprove in OZ

        // call setOperator so the BGT can be claimed to Bearn Voter
        IBeraVault(_beraVault).setOperator(_yBGT);

        //Overrideable initialization since this part will be different for yBGT and Compounding Vaults
        _initialize();
    }

    function stakingAsset() external view returns (address) {
        return address(asset);
    }

    /// @notice Overrideable initialization since this part will be different for yBGT and Compounding Vaults
    function _initialize() internal virtual {}

    function _deployFunds(uint256 amount) internal override {
        beraVault.stake(amount);
    }

    function _freeFunds(uint256 amount) internal override {
        beraVault.withdraw(amount);
    }
}
