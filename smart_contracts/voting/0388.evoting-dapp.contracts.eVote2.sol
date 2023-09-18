// SPDX-License-Identifier: MIT 
pragma solidity >=0.8.0;

contract ElectionFactory2 {
    address public administrator = msg.sender;
    address[] public Elections;

    constructor() {
        administrator = msg.sender;
    }

    function addElection(address[] memory _moderators) public{
        require(msg.sender == administrator, "Only the administrator can add elections.");
        address newElection = address(new Election2(_moderators));
        Elections.push(newElection);
    }

    function getElectionsList() public view returns (address[] memory) {
        return Elections;
    }
}

contract Election2 {
    struct Party {
        string name;
        uint voteCount;
        bool belowThreshold;
    }

    struct Vote {
        uint voteID;
        uint altVoteID;
    }

    Party[] public Parties;
    mapping(address => bool) public Voters;
    Vote[] private Votes;
    address[] public Moderators;
    string public description;
    uint public startTime;
    uint public endTime;
    bool public firstStageLock;
    bool public secondStageLock;

    constructor(address[] memory _moderators) {
        Moderators = _moderators;
        Parties.push(Party("Blank Votes", 0, false));
    }

    function changeParameters(string memory _description, uint _startTime, uint _endTime) public moderatorOnly lockAfterFirstStage{
        description = _description;
        startTime = _startTime;
        endTime = _endTime;
    }

    function addParty(string memory _name) public moderatorOnly lockAfterFirstStage{
        Parties.push(Party(_name, 0, false));
    }

    function vote(uint _partyID, uint _altPartyID) public lockAfterFirstStage{
        require(Voters[msg.sender] == false, "You have already voted.");
        require(startTime < block.timestamp && endTime > block.timestamp, "Election is currently inactive.");
        require(_partyID < Parties.length && _altPartyID < Parties.length, "Invalid vote.");
        Voters[msg.sender] = true;
        Votes.push(Vote(_partyID, _altPartyID));
    }

    function callFirstStage() public moderatorOnly {
        require(firstStageLock == false, "First stage has already been called.");
        firstStageLock = true;

        for(uint256 i = 0; i < Votes.length; i++) {
            Parties[Votes[i].voteID].voteCount += 1;
        }
    }

    function callSecondStage(uint _threshold) public moderatorOnly {
        require(firstStageLock == true, "First stage must be called first.");
        require(secondStageLock == false, "Second stage has already been called.");
        secondStageLock = true;

        for(uint256 i = 1; i < Parties.length; i++) {
            if(Parties[i].voteCount < _threshold) {
                Parties[i].belowThreshold = true;
            }
        }
        for(uint256 i = 0; i < Votes.length; i++) {
            if(Parties[Votes[i].voteID].belowThreshold == true && Parties[Votes[i].altVoteID].belowThreshold == false) {
                Parties[Votes[i].altVoteID].voteCount += 1;
            }
        }
    }

    function getVotesList() public view returns (Vote[] memory) {
        require(firstStageLock == true, "First stage must be called first.");
        return Votes;
    }
    
    function getModeratorsList() public view returns (address[] memory) {
        return Moderators;
    }
    
    function getPartiesList() public view returns (Party[] memory) {
        return Parties;
    }

    function getCurrentTime() public view returns (uint) {
        return block.timestamp;
    }
    
    modifier moderatorOnly {
        bool isUserModerator = false;
        for (uint256 i = 0; i < Moderators.length; i++) {
            if (Moderators[i] == msg.sender) {
                isUserModerator = true;
                break;
            }
        }
        require(isUserModerator, "This function is restricted to election moderators.");
        _;
    }

    modifier lockAfterFirstStage {
        require(firstStageLock == false, "Election is over.");
        _;
    }
}