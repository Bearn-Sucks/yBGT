// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TokenizedStaker} from "@yearn/tokenized-strategy-periphery/Bases/Staker/TokenizedStaker.sol";
import {TokenizedStrategy} from "@yearn/tokenized-strategy/TokenizedStrategy.sol";
import {IBeraVault} from "src/interfaces/IBeraVault.sol";
import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";
import {IBearnBGT} from "src/interfaces/IBearnBGT.sol";


abstract contract BearnVault is TokenizedStaker {
    // @TODO: fork TokenizedStrategy to replace hardcoded address for getting protocol fees

    using SafeERC20 for IERC20;

    IBeraVault public immutable beraVault;
    IBearnVoter public immutable bearnVoter;
    IBearnBGT public immutable yBGT;

    constructor(
        string memory _name,
        address _asset,
        address _beraVault,
        address _yBGT
    ) TokenizedStaker(_asset, _name) {
        beraVault = IBeraVault(_beraVault);
        yBGT = IBearnBGT(_yBGT);

        // set up approvals
        IERC20(_asset).safeApprove(address(beraVault), type(uint256).max);

        // call setOperator so the BGT can be claimed to Bearn Voter
        IBeraVault(_beraVault).setOperator(_yBGT);

        //Overrideable initialization since this part will be different for yBGT and Compounding Vaults
        _initialize();
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
