// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    address public owner;
    string public name;
    string public description;
    bool public isOpen;
    uint public maxOptions;

    struct VotingOption {
        uint id;
        string name;
        uint voteCount;
        bool isActive;
    }

    // guardar las opciones de votacion
    mapping(uint => VotingOption) public votingOptions;

    // personas que ya votaron
    mapping (address => bool) public voters;
    
    // votantes habilitados para esta votacion
    mapping(address => bool) public allowedVoters;

    uint public optionsCount = 0;

    modifier adminOnly {
        require(msg.sender == owner, "Admin only");
        _;
    }

    modifier isVotationOpen() {
        require(isOpen, "Votation is closed");
        _;
    }

    modifier isVotationClosed() {
        require(isOpen != true, "Votation is open cannot be changed");
        _;
    }
    
    modifier validOption(uint _id){
        require(_id < optionsCount && votingOptions[_id].isActive, "Invalid option or it was removed");
        _;
    }

    constructor(string memory _name, string memory _description, uint _maxOptions, address _owner) {
        name = _name;
        description = _description;
        maxOptions = _maxOptions;
        owner = _owner;
    }

    function openVotation() public adminOnly {
        isOpen = true;
    }

    function closeVotation() public adminOnly {
        isOpen = false;
    }

    function addVotingOption(string memory _name) public adminOnly isVotationClosed {
        require(optionsCount < maxOptions, "Max options reached");
        votingOptions[optionsCount] = VotingOption(optionsCount, _name, 0, true);
        optionsCount++;
    }

    function removeVotingOption(uint _id) public adminOnly isVotationClosed validOption(_id) {
        VotingOption storage option = votingOptions[_id];
        option.isActive = false;
    }

    function allowVoter(address _voter) public adminOnly isVotationClosed {
        allowedVoters[_voter] = true;
    }

    function disallowVoter(address _voter) public adminOnly isVotationClosed {
        allowedVoters[_voter] = false;
    }

    function vote(uint _id) public isVotationOpen validOption(_id) {
        require(allowedVoters[msg.sender], "You are not allowed to vote");
        require(voters[msg.sender] == false, "You have already voted");

        voters[msg.sender] = true;
        votingOptions[_id].voteCount++;
    }
}
