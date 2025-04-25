// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBearnVault} from "src/interfaces/IBearnVault.sol";
import {IBearnVaultFactory} from "src/interfaces/IBearnVaultFactory.sol";
import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract YBgtClaimer is Authorized {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event AutoClaimSet(
        address indexed user,
        address indexed vault,
        bool autoClaim
    );

    event AutoClaimAndStakeSet(
        address indexed user,
        address indexed vault,
        bool autoClaimAndStake
    );

    event AutoClaimAndCompoundSet(
        address indexed user,
        address indexed vault,
        bool autoClaimAndCompound
    );

    address public immutable ybgt;

    address public immutable styBgt;

    address public immutable styBgtCompounder;

    address public immutable factory;

    mapping(address => EnumerableSet.AddressSet) private autoClaimVaults;

    mapping(address => EnumerableSet.AddressSet)
        private autoClaimAndStakeVaults;

    mapping(address => EnumerableSet.AddressSet)
        private autoClaimAndCompoundVaults;

    constructor(
        address _authorizer,
        address _styBgtCompounder,
        address _factory
    ) Authorized(_authorizer) {
        styBgtCompounder = _styBgtCompounder;
        styBgt = IBearnVault(_styBgtCompounder).asset();
        ybgt = IBearnVault(styBgt).asset();
        factory = _factory;
    }

    function claim(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            _claim(_vaults[i], msg.sender);
        }

        _transferYbgt(msg.sender);
    }

    function claimAndStake(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            _claim(_vaults[i], msg.sender);
        }
        uint256 ybgtBalance = IERC20(ybgt).balanceOf(address(this));

        if (ybgtBalance > 0) {
            _stake(msg.sender, ybgtBalance);
        }
    }

    function claimAndCompound(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            _claim(_vaults[i], msg.sender);
        }
        uint256 ybgtBalance = IERC20(ybgt).balanceOf(address(this));

        if (ybgtBalance > 0) {
            _stakeInCompounder(msg.sender, ybgtBalance);
        }
    }

    function autoClaim(address[] memory _vaults) public {
        for (uint256 i = 0; i < _vaults.length; i++) {
            autoClaim(_vaults[i]);
        }
    }

    function autoClaim(address _vault) public {
        address[] memory users = autoClaimVaults[_vault].values();

        for (uint256 i = 0; i < users.length; i++) {
            _claim(_vault, users[i]);
            _transferYbgt(users[i]);
        }
    }

    function autoClaimAndStake(address[] memory _vaults) public {
        for (uint256 i = 0; i < _vaults.length; i++) {
            autoClaimAndStake(_vaults[i]);
        }
    }

    function autoClaimAndStake(address _vault) public {
        address[] memory users = autoClaimAndStakeVaults[_vault].values();

        for (uint256 i = 0; i < users.length; i++) {
            _claim(_vault, users[i]);
            uint256 ybgtBalance = IERC20(ybgt).balanceOf(address(this));

            if (ybgtBalance > 0) {
                _stake(users[i], ybgtBalance);
            }
        }
    }

    function autoClaimAndCompound(address[] memory _vaults) public {
        for (uint256 i = 0; i < _vaults.length; i++) {
            autoClaimAndCompound(_vaults[i]);
        }
    }

    function autoClaimAndCompound(address _vault) public {
        address[] memory users = autoClaimAndCompoundVaults[_vault].values();

        for (uint256 i = 0; i < users.length; i++) {
            _claim(_vault, users[i]);
            uint256 ybgtBalance = IERC20(ybgt).balanceOf(address(this));

            if (ybgtBalance > 0) {
                _stakeInCompounder(users[i], ybgtBalance);
            }
        }
    }

    function setAutoClaim(
        address[] memory _vaults,
        bool[] memory _autoClaims
    ) external {
        require(_vaults.length == _autoClaims.length, "lengths mismatch");
        for (uint256 i = 0; i < _vaults.length; i++) {
            address _vault = _vaults[i];
            bool _autoClaim = _autoClaims[i];

            if (_autoClaim && !autoClaimVaults[_vault].contains(msg.sender)) {
                autoClaimVaults[_vault].add(msg.sender);
            } else if (
                !_autoClaim && autoClaimVaults[_vault].contains(msg.sender)
            ) {
                autoClaimVaults[_vault].remove(msg.sender);
            }

            // emit event
            emit AutoClaimSet(msg.sender, _vault, _autoClaim);
        }
    }

    function setAutoClaimAndStake(
        address[] memory _vaults,
        bool[] memory _autoClaims
    ) external {
        require(_vaults.length == _autoClaims.length, "lengths mismatch");
        for (uint256 i = 0; i < _vaults.length; i++) {
            address _vault = _vaults[i];
            bool _autoClaim = _autoClaims[i];

            if (
                _autoClaim &&
                !autoClaimAndStakeVaults[_vault].contains(msg.sender)
            ) {
                autoClaimAndStakeVaults[_vault].add(msg.sender);
            } else if (
                !_autoClaim &&
                autoClaimAndStakeVaults[_vault].contains(msg.sender)
            ) {
                autoClaimAndStakeVaults[_vault].remove(msg.sender);
            }

            // emit event
            emit AutoClaimAndStakeSet(msg.sender, _vault, _autoClaim);
        }
    }

    function setAutoClaimAndCompound(
        address[] memory _vaults,
        bool[] memory _autoClaims
    ) external {
        require(_vaults.length == _autoClaims.length, "lengths mismatch");
        for (uint256 i = 0; i < _vaults.length; i++) {
            address _vault = _vaults[i];
            bool _autoClaim = _autoClaims[i];

            if (
                _autoClaim &&
                !autoClaimAndCompoundVaults[_vault].contains(msg.sender)
            ) {
                autoClaimAndCompoundVaults[_vault].add(msg.sender);
            } else if (
                !_autoClaim &&
                autoClaimAndCompoundVaults[_vault].contains(msg.sender)
            ) {
                autoClaimAndCompoundVaults[_vault].remove(msg.sender);
            }

            // emit event
            emit AutoClaimAndCompoundSet(msg.sender, _vault, _autoClaim);
        }
    }

    function autoClaimAll() public {
        address[] memory vaults = IBearnVaultFactory(factory)
            .getAllBgtEarnerVaults();
        autoClaim(vaults);
    }

    function autoClaimAndStakeAll() public {
        address[] memory vaults = IBearnVaultFactory(factory)
            .getAllBgtEarnerVaults();
        autoClaimAndStake(vaults);
    }

    function autoClaimAndCompoundAll() public {
        address[] memory vaults = IBearnVaultFactory(factory)
            .getAllBgtEarnerVaults();
        autoClaimAndCompound(vaults);
    }

    function _claim(address _vault, address _user) internal {
        uint256[] memory rewards = IBearnVault(_vault).earnedMulti(_user);

        try IBearnVault(_vault).getRewardFor(_user) {} catch {
            return;
        }

        for (uint256 i = 0; i < rewards.length; i++) {
            address reward = IBearnVault(_vault).rewardTokens(i);

            if (reward == ybgt) continue;

            uint256 balance = IERC20(reward).balanceOf(address(this));

            if (balance == 0) continue;

            IERC20(reward).safeTransfer(_user, balance);
        }
    }

    function _transferYbgt(address _user) internal {
        uint256 ybgtBalance = IERC20(ybgt).balanceOf(address(this));

        if (ybgtBalance > 0) {
            IERC20(ybgt).safeTransfer(_user, ybgtBalance);
        }
    }

    function _stake(address _user, uint256 _amount) internal {
        IERC20(ybgt).forceApprove(styBgt, _amount);
        IBearnVault(styBgt).deposit(_amount, _user);
    }

    function _stakeInCompounder(address _user, uint256 _amount) internal {
        _stake(address(this), _amount);
        IERC20(styBgt).forceApprove(styBgtCompounder, _amount);
        IBearnVault(styBgtCompounder).deposit(_amount, _user);
    }

    function rescue(address _token) external isAuthorized(MANAGER_ROLE) {
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
