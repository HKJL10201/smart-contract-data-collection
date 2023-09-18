// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./ISBToken.sol";
import "./Voting.sol";

/**
 * VotingFactory is a factory to create Votings
 * Allows user to update their basic info
 */
contract VotingFactory {
    /**
     * Addresses array of created votings
     */
    address[] private deployedVotings;

    address private sbtAddress;

    /**
     * Mapping to have a copy of Votings
     */
    mapping(address => Voting) private votings;

    /**
     * Moderators modifier
     * Moderators can add/remove users to/from KYC
     */
    modifier onlyModerator() {
        require(
            ISBToken(sbtAddress).getRole(msg.sender) > 0,
            "Not a Moderator!"
        );
        _;
    }

    /**
     * Admin modifier
     * Admin can add/remove moderators and users to/from KYC
     */
    modifier onlyAdmin() {
        require(ISBToken(sbtAddress).getRole(msg.sender) == 2, "Not an Admin!");
        _;
    }

    /**
     * Identification modifier
     * Requires basic information about the user (name, email, age)
     * Indentified user can vote and create votings
     */
    modifier onlyIdentified(address _owner) {
        require(
            ISBToken(sbtAddress).getOwner(msg.sender) != address(0),
            "Identity not found"
        );
        _;
    }

    event VotingsDeployed(
        string indexed _title,
        address indexed _chairPerson,
        address _votingAddress
    );

    constructor(address _sbtAddress) {
        sbtAddress = _sbtAddress;
    }

    function changeAddrContr(address _addr) public onlyAdmin {
        sbtAddress = _addr;
    }

    /**
     * Function for creating voting
     * Requires KYC for only KYC'd users voting
     * Voting time from 1 hour to 1 month
     */
    function createVoting(
        string memory title,
        string[] memory proposalNames,
        uint durationMinutes,
        bool isKYC,
        bool isPrivate
    ) public onlyIdentified(msg.sender) returns (address) {
        if (
            ISBToken(sbtAddress).checkKYC(msg.sender) == false && isKYC == true
        ) {
            revert("Only for KYC'ed users");
        }

        Voting newVoting = new Voting(
            title,
            proposalNames,
            durationMinutes,
            msg.sender,
            isKYC,
            isPrivate
        );

        address newVotingAddress = address(newVoting);
        deployedVotings.push(newVotingAddress);
        votings[newVotingAddress] = newVoting;

        emit VotingsDeployed(title, msg.sender, newVotingAddress);

        return newVotingAddress;
    }

    function getSBTAddress() public view returns (address) {
        return sbtAddress;
    }

    /**
     * Getter, return addresses array of created votings
     */
    function getDeployedVotings() public view returns (address[] memory) {
        return deployedVotings;
    }

    /**
     * Getter, returns winner of voting session
     */
    function getVotiongWinnerName(
        address votingAddress
    ) public view returns (string memory) {
        Voting voting = votings[votingAddress];

        return voting.getWinnerName();
    }
}
