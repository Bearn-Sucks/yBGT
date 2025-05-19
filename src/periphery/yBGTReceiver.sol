// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";
import {BearnExecutor} from "../bases/BearnExecutor.sol";
import {BearnBGT} from "../BearnBGT.sol";
import {IStakedBearnBGT} from "../interfaces/IStakedBearnBGT.sol";
import {IVault} from "@yearn/vaults-v3/interfaces/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {UniswapV3Swapper} from "@yearn/tokenized-strategy-periphery/swappers/UniswapV3Swapper.sol";

// Contract will
// Receive all the yBGT taken as fees
// Stake it in the styBGT contract
// Use the Honey earned from stybgt to buy back yBGT and then send the target amount to the bribe manager
contract yBGTReceiver is Authorized, BearnExecutor, UniswapV3Swapper {
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    uint256 internal constant MAX_BPS = 10_000;

    BearnBGT public immutable yBGT;

    IStakedBearnBGT public immutable styBGT;

    ERC20 public immutable wbera;

    IVault public immutable yBERA;

    ERC20 public immutable honey;

    address public immutable treasury;

    address public bribeManager;

    uint256 public bribeRatio;

    constructor(
        address _authorizer,
        address _styBGT,
        address _yBera,
        address _bribeManager,
        uint256 _bribeRatio,
        address _treasury
    ) Authorized(_authorizer) {
        styBGT = IStakedBearnBGT(_styBGT);
        yBGT = BearnBGT(styBGT.yBGT());
        honey = ERC20(styBGT.honey());
        yBERA = IVault(_yBera);
        wbera = ERC20(yBERA.asset());
        treasury = _treasury;

        bribeManager = _bribeManager;
        bribeRatio = _bribeRatio;

        yBGT.approve(address(styBGT), type(uint256).max);

        base = address(wbera);
        router = 0xEd158C4b336A6FCb5B193A5570e3a571f6cbe690;

        _setUniFees(address(honey), address(wbera), 3000);
        _setUniFees(address(yBERA), address(yBGT), 3000);
    }

    function setBribeManager(
        address _bribeManager
    ) external isAuthorized(MANAGER_ROLE) {
        bribeManager = _bribeManager;
    }

    function setBribeRatio(
        uint256 _bribeRatio
    ) external isAuthorized(MANAGER_ROLE) {
        require(_bribeRatio <= MAX_BPS, "Invalid bribe ratio");
        bribeRatio = _bribeRatio;
    }

    function compound() external isAuthorized(KEEPER_ROLE) {
        uint256 yBGTBalance = yBGT.balanceOf(address(this));

        uint256 bribeAmount = (yBGTBalance * bribeRatio) / MAX_BPS;

        styBGT.getRewardFor(treasury);
        
        _swapHoney();

        yBGT.transfer(bribeManager, bribeAmount);

        uint256 yBGTBalanceAfter = yBGT.balanceOf(address(this));

        if (yBGTBalanceAfter > 0) {
            styBGT.deposit(yBGTBalanceAfter, treasury);
        }
    }

    function _swapHoney() internal {
        uint256 _amount = honey.balanceOf(address(this));
        if (_amount == 0) return;

        // Swap honey to wbera
        base = address(wbera);
        _swapFrom(address(honey), address(wbera), _amount, 0);

        // Deposit wbera into yBERA
        uint256 wberaBalance = wbera.balanceOf(address(this));
        wbera.approve(address(yBERA), wberaBalance);
        yBERA.deposit(wberaBalance, address(this));

        // Swap yBera to yBGT
        base = address(yBERA);
        _swapFrom(
            address(yBERA),
            address(yBGT),
            yBERA.balanceOf(address(this)),
            0
        );
    }

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

    function rescue(address token, address to, uint256 amount) external isAuthorized(GOVERNANCE_ROLE) {
        ERC20(token).transfer(to, amount);
    }
}
