// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

/// @title Voting smart contract
/// @author Bahador GhadamKheir
/// @notice This is a sample voting smart contract for educational purposes
contract Voting {

    // Start time of voting
    uint startVoting; 

    // End of voting time
    uint endVoting; 

    // Voter informations
    struct Voter {
        // Has voter, voted any candidate yet or not
        bool voted; 

        // Who is vote of the voter
        uint8 voteTo;

        // Manage vote value of the voter
        uint weight;
    }

    // Candidate informations
    struct Candidate {
        // bytes32 is prefered than string, because of gas efficiency
        bytes32 name; 

        // How many votes earned by the candidate
        uint voteCount;
    }

    // Account address of the voting manager
    address public manager;

    // Account address of voters
    mapping(address => Voter) public voters;

    // Keeping candidate info
    Candidate[] public candidates; // [(name,voteCount),(name,voteCount), ...]

    event CandidateAdded(bytes32 candidateName, uint CandidateID);
    event VotingStarted(uint StartTime);
    event VotingEnded(uint EndTime);
    event Voted(bytes32 candidate, uint currentVoteCount);

    // Function modifier to check voting duration availabity
    modifier ActiveVoting {
        require(
            block.timestamp >= startVoting &&
            block.timestamp <= endVoting,
            "Voting is not enable right now"
        );
        _;
    }

    // Function modidier to ckeck if msg.sender is the admin of contract
    modifier onlyOwner {
        require(msg.sender == manager, "You are not manager");
        _;
    }


    /// @param _candidatesName bytes32 formatted name of candidates
    constructor(bytes32[] memory _candidatesName) {
        // Setting the voting manager
        manager = msg.sender;

        // Giving 1 voting right to the manager
        voters[manager].weight = 1;

        for(uint i=0; i < _candidatesName.length; i++) {
            // Initializing candidates at deployment time
            candidates.push(Candidate({
                name: _candidatesName[i],
                // each candidate has starting voteCount of 0
                voteCount: 0
            }));
        }
    }

    /// @notice Admin can give voting right to each specific voter
    /// @param _voter account address of voter
    function giveRightToVote(address _voter) public onlyOwner {
        // checking if voter has voted before
        require(!voters[_voter].voted, "This address already voted");

        /// check if there is any votes right set before
        require(voters[_voter].weight == 0);
        // setting voter's right
        voters[_voter].weight = 1;
    }

    /// @notice Voter can give vote to a specific candidate by using this function
    /// @param _cadidate if of specific candidate
    function vote(uint8 _cadidate) public ActiveVoting {
        // Implementing a pointer to the Voter struct sorage slot location
        Voter storage sender = voters[msg.sender];
        
        // checking if voter not voted yet
        require(!sender.voted, " You already voted");

        // Voter gave the vote
        sender.voted = true;

        // Who is the selected candidate of the voter
        sender.voteTo = _cadidate;

        // Selected candidate's vote# goes up by 1
        candidates[_cadidate].voteCount += sender.weight;

        // A vote event will be triggered 
        emit Voted(candidates[_cadidate].name, candidates[_cadidate].voteCount);
    }

    /// @notice Showing winning candidateID
    /// @return _winnerID Id of winning candidate
    function winningCandidateID() public view returns(uint _winnerID) {
        uint winningVoteCount = 0;
        for(uint i =0; i < candidates.length;i++) {
            if(candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                _winnerID = i;
            }
        }
    }
    /// @notice Showing winning candidate name
    /// @return Name of winning candidate
    function winningCandidateName() public view returns(string memory) {
        bytes32 _winnerName = candidates[winningCandidateID()].name;
        return string(abi.encodePacked(_winnerName));
    }

    /// @notice Manager can set when will the voting process start
    /// @param _startVoting Voting start time in epoch format
    function setStartTime(uint _startVoting) public onlyOwner {
        startVoting = _startVoting;
        emit VotingStarted(startVoting);
    }

    /// @notice Manager can set when will the voting process End
    /// @param _endVoting Voting end time in epoch format
    function setEndTime(uint _endVoting) public onlyOwner {
        endVoting = _endVoting;
        emit VotingEnded(endVoting);
    }

    /// @notice To stop the voting process in emergency circumstances.
    /// Can be called by Manager.
    /// Only applicable when voting process is active.
    function emergencyEndOfVoting() public onlyOwner ActiveVoting {
        endVoting = block.timestamp;
        emit VotingEnded(endVoting);
    }

    /// @notice To show candidates info
    /// @return Information of all the candidates
    function showCandidates() public view returns(Candidate[] memory) {
        return candidates;
    }

    /// @notice Show a specific candidate information
    /// @param _ID ID of a specific candidate
    /// @return Name of the candidate in bytes32 format
    /// @return Vote count of the candidate
    /// @return ID of the candidate
    function showCandidateInfo(uint _ID) public view returns(bytes32, uint, uint) {
        uint candidateID = _ID;
        return (
            candidates[candidateID].name,
            candidates[candidateID].voteCount,
            candidateID
        );
    }

    /// @notice Manaager can add specific candidate after the deployment.
    /// @param _name Name of candidate in bytes32 format
    function addCandidate(bytes32 _name) public onlyOwner {
        // bytes32: 0x... --> 0-9 a-f
        // pushing candidate info into the candidates information array
        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));


        // destructuring function to show new candidate information by triggering CandidateAdded event
        (bytes32 _candidateName, , uint _candidateID) = showCandidateInfo(candidates.length - 1);
        emit CandidateAdded(_candidateName, _candidateID);
    }
}
