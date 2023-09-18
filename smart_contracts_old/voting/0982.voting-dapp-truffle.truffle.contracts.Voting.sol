// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

/// @title A voting contract
/// @author Vinay Pallegar
/// @notice You can use this contract for basic voting mechanisms
/// @dev Only addresses added to the voterRegistry are able to interact
contract Voting is Ownable {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        bool open;
    }

    struct voter{
        string voterName;
        address voterAddress;
        bool voted;
        bool exists;
        uint choiceId;
        string choice;
        uint timestamp;
    }
    
    bool public stopped = false;

    uint public totalCandidates = 0;
    uint public totalVotes = 0;
    uint public totalVoters = 0;

    /** Contract owner */
    voter[] private voterList;
    
    mapping(address => voter) public voterRegister;
    mapping(uint => Candidate) public candidateLookup;


    /// @notice Upon contract creation, add some default candidates/owner as user.
	constructor() public {

        addVoter(msg.sender, "Admin");

    }

    /// @notice Circuit breaker to stop any further votes from being added.
    modifier stopInEmergency { 
        require(!stopped); 
        _; 
    }

    /// @notice Only allows users within voterRegistry to access
    modifier onlyUsers {
        require(bytes(voterRegister[msg.sender].voterName).length != 0, "Access Denied");
        _;
    }

    // Events
    event voterAdded(address voter);
    event votedEvent(uint indexed id);
    event candidateAdded(uint indexed id);
    event candidateVisibilityChange(Candidate candidate);

    /// @notice Kill contract and remove from blockchain
    /// @dev Uses Ownable contract
    function kill() public onlyOwner {
           if(msg.sender == owner()) selfdestruct(address(uint160(owner())));
    }

    /// @notice Changes Circuit Breaker status to stop voting/displaying candidates
    /// @dev Changes state variable
    /// @param _mode Set stopped to either true or false
    function changeEmergencyMode(bool _mode) public onlyOwner {
        stopped = _mode; 
    }   

    /// @notice Check to see if user is the owner
    function checkIsOwner() public view returns (bool) {
        return msg.sender == owner() ? true : false;
    }

    /// @notice Add new candidate for voting
    /// @dev Candidates could have a uniqueID created before pushing for better management
    /// @param name The candidate name for display
    function addCandidate(string memory name) public onlyOwner {
        candidateLookup[totalCandidates] = Candidate(totalCandidates, name, 0, true);
        totalCandidates++; 
        emit candidateAdded(totalCandidates);
    }    

    /// @notice Change candidate visiblity for voting
    /// @param _id Candidate index #
    /// @param _view Visbility
    function changeCandidateVisibility(uint _id, bool _view) public onlyOwner returns (Candidate memory) {
        require(bytes(candidateLookup[_id].name).length != 0, "Candidate not found");
        candidateLookup[_id].open = _view;
        emit candidateVisibilityChange(candidateLookup[_id]);
        return candidateLookup[_id];
    }

    /// @notice Add address into system for access to voting
    /// @dev Side-effects observed here
    /// @param _voterAddress The address of the account to add
    /// @param _voterName The friendly name of the account to add, ie firstname/lastname
    function addVoter(address _voterAddress, string memory _voterName) public onlyOwner {
        voter memory v;
        v.voterName = _voterName;
        v.voterAddress = _voterAddress;
        v.voted = false;
        v.exists = true;
        v.timestamp = block.timestamp;
        voterRegister[_voterAddress] = v;
        voterList.push(v);
        totalVoters++;
        emit voterAdded(_voterAddress);
    }

    /// @notice Check to see if user is allowed to vote.
    /// @return bool If user is allowed to access this voting system
    function getUserVoteAccessInfo() external view returns (bool) {
            return voterRegister[msg.sender].exists ? true : false;
    }

    /// @notice Check to see if user has already casted a vote
    /// @dev ChoiceId is based on index of candidates
    /// @return bool If has voted
    /// @return uint ChoiceID of the selected vote
    function getUserVotedInfo() external view returns (bool, uint) {
        return (voterRegister[msg.sender].voted, voterRegister[msg.sender].voted ? voterRegister[msg.sender].choiceId : 0);
    }

    /// @notice Save vote by user
    /// @dev choiceID is index of selected candidate
    /// @param id Index of selected candidate
    /// @param choice Friendly name of selected candidate
    /// @return uint choiceId of selected candidate.
    function doVote(uint id, string calldata choice) external stopInEmergency onlyUsers returns (uint) {
        require (id >= 0 && id <= totalCandidates-1, "Invalid  vote casted.");
        require (!voterRegister[msg.sender].voted, "Address has already voted.");
        require (candidateLookup[id].open, "Selected candidate voting is not open");
        
        if (bytes(voterRegister[msg.sender].voterName).length != 0 && !voterRegister[msg.sender].voted){
            voterRegister[msg.sender].voted = true;
            voterRegister[msg.sender].choice = choice;
            voterRegister[msg.sender].choiceId = id;
            candidateLookup[id].voteCount++;
            totalVotes++;
        }
        emit votedEvent(id);
        return voterRegister[msg.sender].choiceId;
    }

    /// @notice Public view for showing all open:true candidates in system
    /// @return string[] Candidate Names
    /// @return uint[] Candidate Vote Totals
    function viewAllCandidates() external view stopInEmergency onlyUsers returns (string[] memory, uint[] memory) {
        string[] memory candidateNames = new string[](totalCandidates);
        uint[] memory voteTotals = new uint[](totalCandidates);

        for (uint i = 0; i < totalCandidates; i++) {
            if (candidateLookup[i].open) {
                candidateNames[i] = candidateLookup[i].name;
                voteTotals[i] = candidateLookup[i].voteCount;
            }
        }

        return (candidateNames, voteTotals);
    }

    /// @notice Public view for admins to get all candidates with status
    /// @return string[] Candidate Names
    /// @return bool[] Candidate Status
    /// @return uint[] Candidate Vote Totals
    function getAllCandidates() external view onlyOwner returns (string[] memory, bool[] memory, uint[] memory) {
        string[] memory candidateNames = new string[](totalCandidates);
        bool[] memory candidateStatus = new bool[](totalCandidates);
        uint[] memory voteTotals = new uint[](totalCandidates);

        for (uint i = 0; i < totalCandidates; i++) {
                candidateNames[i] = candidateLookup[i].name;
                candidateStatus[i] = candidateLookup[i].open;
                voteTotals[i] = candidateLookup[i].voteCount;
        }

        return (candidateNames, candidateStatus, voteTotals);
    }

    /// @notice Public view for showing all users in the system for Admin only
    /// @return voter[] User Name
    function getAllVoters() public view onlyOwner returns (voter[] memory) {
        return voterList;
    }


}
