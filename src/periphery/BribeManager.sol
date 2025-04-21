// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.18;

import {IVault} from "@yearn/vaults-v3/interfaces/IVault.sol";

import {BearnExecutor} from "../bases/BearnExecutor.sol";
import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {IBeraVault} from "../interfaces/IBeraVault.sol";
import {IERC20Metadata} from "../interfaces/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BribeManager is Authorized, BearnExecutor {
    using SafeERC20 for IERC20;

    IBeraVault public immutable beraVault;

    IVault public immutable yBERA;

    address public immutable WBERA;

    constructor(
        address _authorizer,
        address _beraVault,
        address _yBERA
    ) Authorized(_authorizer) {
        beraVault = IBeraVault(_beraVault);
        yBERA = IVault(_yBERA);
        WBERA = yBERA.asset();
    }

    function name() external view returns (string memory) {
        return
            string.concat(
                IERC20Metadata(beraVault.stakeToken()).symbol(),
                "BribeManager"
            );
    }

    function redeemYbera() external {
        yBERA.redeem(
            yBERA.balanceOf(address(this)),
            address(this),
            address(this)
        );
    }

    function balanceOfIncentiveTokens()
        external
        view
        returns (uint256[] memory _balances)
    {
        address[] memory incentiveTokens = beraVault.getWhitelistedTokens();
        _balances = new uint256[](incentiveTokens.length);
        for (uint256 i = 0; i < incentiveTokens.length; i++) {
            _balances[i] = IERC20(incentiveTokens[i]).balanceOf(address(this));
        }
    }

    function addIncentive(
        address token,
        uint256 amount,
        uint256 incentiveRate
    ) external isAuthorized(MANAGER_ROLE) {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        IERC20(token).forceApprove(address(beraVault), amount);
        beraVault.addIncentive(token, amount, incentiveRate);
    }

    function accountIncentives(
        address token,
        uint256 amount
    ) external isAuthorized(MANAGER_ROLE) {
        beraVault.accountIncentives(token, amount);
    }

    /// @param to Tx destination
    /// @param value Tx value
    /// @param data Tx data
    /// @param operation Call or delegate call
    /// @param allowFailure Allow failure or revert
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        bool allowFailure
    )
        public
        payable
        isAuthorized(GOVERNANCE_ROLE)
        returns (bool success, bytes memory _returndata)
    {
        return _execute(to, value, data, operation, allowFailure);
    }
}
