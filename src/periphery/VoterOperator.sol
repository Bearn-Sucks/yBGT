// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {IBGT} from "@berachain/contracts/pol/BGT.sol";

import {Authorized} from "@bearn/governance/contracts/bases/Authorized.sol";
import {IBearnVoterManager} from "../interfaces/IBearnVoterManager.sol";

contract VoterOperator is Authorized {

    address[] public incentiveTokens;
    
    mapping(address => bool) public isIncentiveToken;

    IBearnVoterManager public immutable voterManager;

    IBGT public immutable bgt;

    address public immutable bearnVoter;

    bytes public validatorPubkey;

    uint256 public minToBoost;

    constructor(address _authorizer, address _voterManager, bytes memory _validatorPubkey) Authorized(_authorizer) {
        voterManager = IBearnVoterManager(_voterManager);
        bgt = IBGT(voterManager.bgt());
        bearnVoter = address(voterManager.bearnVoter());
        validatorPubkey = _validatorPubkey;
        minToBoost = 10e18;
    }

    function fundAuction(address _token) external {
        require(isIncentiveToken[_token], "Token is not an incentive token");
        voterManager.fundAuction(_token);
    }

    function addIncentiveToken(address _token) external isAuthorized(MANAGER_ROLE) {
        require(!isIncentiveToken[_token], "Token is already an incentive token");
        isIncentiveToken[_token] = true;
        incentiveTokens.push(_token);
    }

    function removeIncentiveToken(address _token) external isAuthorized(MANAGER_ROLE) {
        require(isIncentiveToken[_token], "Token is not an incentive token");
        isIncentiveToken[_token] = false;
        for (uint256 i = 0; i < incentiveTokens.length; i++) {
            if (incentiveTokens[i] == _token) {
                incentiveTokens[i] = incentiveTokens[incentiveTokens.length - 1];
                incentiveTokens.pop();
                break;
            }
        }
    }

    function setValidatorPubkey(bytes calldata _validatorPubkey) external isAuthorized(MANAGER_ROLE) {
        validatorPubkey = _validatorPubkey;
    }

    function setMinToBoost(uint256 _minToBoost) external isAuthorized(MANAGER_ROLE) {
        minToBoost = _minToBoost;
    }

    function getIncentiveTokens() external view returns (address[] memory) {
        return incentiveTokens;
    }

    function boostable() public view returns (uint256) {
        (uint32 blockNumberLast, uint128 balance) = bgt.boostedQueue(address(bearnVoter), validatorPubkey);
        if (balance > 0) {
            if (blockNumberLast + bgt.activateBoostDelay() > block.number) {
                return 0;
            }
        }

        return bgt.unboostedBalanceOf(address(bearnVoter));
    }

    function shouldBoost() external view returns (bool, bytes memory) {
        uint256 amount = boostable();
        if (amount < minToBoost) {
            return (false, "not enough balance");
        }

        return (true, abi.encodeWithSelector(VoterOperator.queueBoost.selector));
    }

    function queueBoost() external {
        ( , uint128 balance) = bgt.boostedQueue(address(bearnVoter), validatorPubkey);

        if (balance > 0) {
            activateBoost();
        }

        uint256 amount = bgt.unboostedBalanceOf(address(bearnVoter));

        if (amount > minToBoost) {
            voterManager.queueBoost(validatorPubkey, uint128(amount));
        }
    }

    function activateBoost() public {
        require(bgt.activateBoost(address(bearnVoter), validatorPubkey), "Failed to activate boost");
    }
}