// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {IBGT} from "@berachain/contracts/pol/BGT.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";
import {IBearnVoterManager} from "../interfaces/IBearnVoterManager.sol";

import {Auction} from "@yearn/tokenized-strategy-periphery/Auctions/Auction.sol";

contract VoterOperator is Authorized {
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    address[] public incentiveTokens;

    mapping(address => bool) public isIncentiveToken;

    IBearnVoterManager public immutable voterManager;

    IBGT public immutable bgt;

    address public immutable bearnVoter;

    bytes[] public validatorPubkeys;

    uint256 public minToBoost;

    constructor(
        address _authorizer,
        address _voterManager
    ) Authorized(_authorizer) {
        voterManager = IBearnVoterManager(_voterManager);
        bgt = IBGT(voterManager.bgt());
        bearnVoter = address(voterManager.bearnVoter());
        minToBoost = 100e18;
    }

    function fundAuction(address _token) external {
        (, uint64 scaler, ) = Auction(voterManager.auction()).auctions(_token);
        require(scaler != 0, "Token is not an auction");
        voterManager.fundAuction(_token);
    }

    function setValidatorPubkeys(
        bytes[] memory _validatorPubkeys
    ) external isAuthorized(MANAGER_ROLE) {
        validatorPubkeys = _validatorPubkeys;
    }

    function setMinToBoost(
        uint256 _minToBoost
    ) external isAuthorized(MANAGER_ROLE) {
        minToBoost = _minToBoost;
    }

    function getIncentiveTokens() external view returns (address[] memory) {
        return incentiveTokens;
    }

    function boostable() public view returns (uint256) {
        bool openValidator = false;
        uint256 boostDelay = bgt.activateBoostDelay();
        for (uint256 i = 0; i < validatorPubkeys.length; i++) {
            (uint32 blockNumberLast, uint128 balance) = bgt.boostedQueue(
                address(bearnVoter),
                validatorPubkeys[i]
            );
            if (balance > 0 && blockNumberLast + boostDelay > block.number)
                continue;

            openValidator = true;
            break;
        }

        return openValidator ? bgt.unboostedBalanceOf(address(bearnVoter)) : 0;
    }

    function shouldBoost() external view returns (bool, bytes memory) {
        uint256 amount = boostable();
        if (amount < minToBoost) {
            return (false, "not enough balance");
        }

        return (
            true,
            abi.encodeWithSelector(VoterOperator.queueBoost.selector)
        );
    }

    function queueBoost() external isAuthorized(KEEPER_ROLE) {
        activateBoosts();

        uint256 amount = bgt.unboostedBalanceOf(address(bearnVoter));

        if (amount > minToBoost) {
            for (uint256 i = 0; i < validatorPubkeys.length; i++) {
                (, uint128 balance) = bgt.boostedQueue(
                    address(bearnVoter),
                    validatorPubkeys[i]
                );

                if (balance > 0) continue;

                voterManager.queueBoost(validatorPubkeys[i], uint128(amount));
            }
        }
    }

    function activateBoosts() public {
        uint256 boostDelay = bgt.activateBoostDelay();
        for (uint256 i = 0; i < validatorPubkeys.length; i++) {
            (uint32 blockNumberLast, uint128 balance) = bgt.boostedQueue(
                address(bearnVoter),
                validatorPubkeys[i]
            );

            if (balance > 0 && blockNumberLast + boostDelay < block.number) {
                activateBoost(validatorPubkeys[i]);
            }
        }
    }

    function activateBoost(bytes memory validatorPubkey) public {
        require(
            bgt.activateBoost(address(bearnVoter), validatorPubkey),
            "Failed to activate boost"
        );
    }
}
