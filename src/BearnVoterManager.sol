// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IGovernor as IBeraGovenor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBGT} from "@berachain/contracts/pol/BGT.sol";
import {IBGTStaker} from "@berachain/contracts/pol/BGTStaker.sol";
import {WBERA} from "@berachain/contracts/WBERA.sol";

import {IStakedBearnBGT} from "src/interfaces/IStakedBearnBGT.sol";
import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";
import {AuctionFactory} from "@yearn/tokenized-strategy-periphery/Auctions/AuctionFactory.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";

import {IBearnVoter} from "src/interfaces/IBearnVoter.sol";

/// @title BearnVoterManager
/// @author Bearn.sucks
/// @notice
///   Contract that manages BearnVoter and handles Berachain governance logic.
///   Can be swapped for another contract if Berachain ever upgrades its governance functions
contract BearnVoterManager is Authorized {
    IBGT public immutable bgt;
    IBGTStaker public immutable bgtStaker;
    WBERA public immutable wbera;
    IERC20 public immutable honey;
    IBeraGovenor public immutable beraGovernance;

    IBearnVoter public immutable bearnVoter;
    IStakedBearnBGT public immutable styBGT;

    Auction public immutable auction;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /* ========== CONSTRUCTOR AND INITIALIZER ========== */
    constructor(
        address _authorizer,
        address _bgt,
        address _bgtStaker,
        address _wbera,
        address _honey,
        address _beraGovernance,
        address _bearnVoter,
        address _styBGT
    ) Authorized(_authorizer) {
        bgt = IBGT(_bgt);
        bgtStaker = IBGTStaker(_bgtStaker);
        wbera = WBERA(payable(_wbera));
        honey = IERC20(_honey);
        beraGovernance = IBeraGovenor(_beraGovernance);
        styBGT = IStakedBearnBGT(_styBGT);

        bearnVoter = IBearnVoter(_bearnVoter);

        // Use Yearn AuctionFactory to deploy an Auction
        auction = Auction(
            AuctionFactory(0xCfA510188884F199fcC6e750764FAAbE6e56ec40)
                .createNewAuction(
                    address(honey),
                    address(bearnVoter),
                    styBGT.management(),
                    1 days,
                    5_000
                )
        );
    }

    /* ========== VOTING ========== */

    function submitProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external isAuthorized(MANAGER_ROLE) returns (uint256 proposalId) {
        bytes memory data = abi.encodeCall(
            beraGovernance.propose,
            (targets, values, calldatas, description)
        );

        (, bytes memory _returndata) = bearnVoter.execute(
            address(beraGovernance),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        return abi.decode(_returndata, (uint256));
    }

    function submitVotes(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) external isAuthorized(MANAGER_ROLE) returns (uint256 balance) {
        bytes memory data = abi.encodeCall(
            beraGovernance.castVoteWithReasonAndParams,
            (proposalId, support, reason, params)
        );

        (, bytes memory _returndata) = bearnVoter.execute(
            address(beraGovernance),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        return abi.decode(_returndata, (uint256));
    }

    /* ========== BOOSTING ========== */
    function queueBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external isAuthorized(OPERATOR_ROLE) {
        // Fetch max available if type(uint128).max is passed
        if (amount == type(uint128).max) {
            amount = uint128(bgt.unboostedBalanceOf(address(bearnVoter))); // Input real amounts if this will overflow
        }

        bytes memory data = abi.encodeCall(bgt.queueBoost, (pubkey, amount));

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    function cancelBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external isAuthorized(OPERATOR_ROLE) {
        // Fetch max available if type(uint128).max is passed
        if (amount == type(uint128).max) {
            (, amount) = bgt.boostedQueue(address(bearnVoter), pubkey);
        }

        bytes memory data = abi.encodeCall(bgt.cancelBoost, (pubkey, amount));

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    /// @notice Activates already queued boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function activateBoost(bytes calldata pubkey) external returns (bool) {
        return bgt.activateBoost(address(bearnVoter), pubkey);
    }

    function queueDropBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external isAuthorized(OPERATOR_ROLE) {
        // Fetch max available if type(uint128).max is passed
        if (amount == type(uint128).max) {
            amount = bgt.boosted(address(bearnVoter), pubkey);
        }

        bytes memory data = abi.encodeCall(
            bgt.queueDropBoost,
            (pubkey, amount)
        );

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    function cancelDropBoost(
        bytes calldata pubkey,
        uint128 amount
    ) external isAuthorized(OPERATOR_ROLE) {
        // Fetch max available if type(uint128).max is passed
        if (amount == type(uint128).max) {
            (, amount) = bgt.dropBoostQueue(address(bearnVoter), pubkey);
        }

        bytes memory data = abi.encodeCall(
            bgt.cancelDropBoost,
            (pubkey, amount)
        );

        bearnVoter.execute(
            address(bgt),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );
    }

    /// @notice Drops already queued drop boost
    /// @dev Left open to the public since anyone can activate boost that is queued and ready
    /// @param pubkey Public key of the boostee
    function dropBoost(bytes calldata pubkey) external returns (bool) {
        return bgt.dropBoost(address(bearnVoter), pubkey);
    }

    /* ========== REWARDS ========== */
    function getReward() external returns (uint256) {
        // Gated so only styBGT can call this
        require(msg.sender == address(styBGT), "!authorized");

        // Claim rewards
        bytes memory data = abi.encodeCall(bgtStaker.getReward, ());

        bearnVoter.execute(
            address(bgtStaker),
            0,
            data,
            IBearnVoter.Operation.Call,
            false
        );

        // Transfer Full balance of honey to styBGT to account for auctions.
        uint256 amount = honey.balanceOf(address(bearnVoter));

        // Send rewards to styBGT
        if (amount > 0) {
            data = abi.encodeCall(IERC20.transfer, (address(styBGT), amount));
            bearnVoter.execute(
                address(honey),
                0,
                data,
                IBearnVoter.Operation.Call,
                false
            );
        }

        return amount;
    }

    /// @notice Funds an auction with the reward claimed to the voter.
    /// @dev The token must have been enabled by vaultManager in order to be kicked.
    function fundAuction(address _token) external isAuthorized(OPERATOR_ROLE) {
        // Transfer Full balance of reward token to auction
        uint256 amount = IERC20(_token).balanceOf(address(bearnVoter));

        // Send rewards to auction
        if (amount > 0) {
            bytes memory data = abi.encodeCall(
                IERC20.transfer,
                (address(auction), amount)
            );
            bearnVoter.execute(
                address(_token),
                0,
                data,
                IBearnVoter.Operation.Call,
                false
            );
        }

        // Kick auction
        auction.kick(_token);
    }
}
