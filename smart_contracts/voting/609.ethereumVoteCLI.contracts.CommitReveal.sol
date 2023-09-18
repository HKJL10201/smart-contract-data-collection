pragma solidity 0.4.25;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;


contract CommitReveal {
    // The two choices for your vote
    string public choice1;
    string public choice2;
    
    // Information about the current status of the vote
    uint256 public votesForChoice1;
    uint256 public votesForChoice2;
    uint256 public commitPhaseEndTime;
    uint256 public numberOfVotesCast = 0;

    // The actual votes and vote commits
    bytes32[] public voteCommits;
    mapping(bytes32 => string) public voteStatuses; // Either `Committed` or `Revealed`
    
    // Events used to log what's going on in the contract
    event NewVoteCommit(bytes32 commit);
    event NewVoteReveal(bytes32 commit, string choice);
    
    // Constructor used to set parameters for the this specific vote
    constructor(
        uint256 _phaseLengthInSeconds, 
        string _choice1, 
        string _choice2
    ) public {
        require(
            _phaseLengthInSeconds >= 0,
            "Commit phase cannot be less than 20 seconds."
        );
        commitPhaseEndTime = now + _phaseLengthInSeconds;
        choice1 = _choice1;
        choice2 = _choice2;
    }

    modifier onlyDuringCommitPhase() {
        require(
            now < commitPhaseEndTime,
            "Only allowed to commit during committing period."
        );
        _;
    }

    modifier onlyAfterCommitPhase() {
        require(
            now > commitPhaseEndTime,
            "Only allowed to get winner after commit phase is over."
        );
        _;
    }

    modifier onlyWhenAllVotesAreCounted() {
        require(
            votesForChoice1 + votesForChoice2 == voteCommits.length,
            "Can only get winner when all votes are revealed."
        );
        _;
    }
    
    function commitVote(bytes32 voteCommit) public onlyDuringCommitPhase {
        // Check if this commit has been used before
        bytes memory bytesVoteCommit = bytes(voteStatuses[voteCommit]);
        require(
            bytesVoteCommit.length == 0,
            "This commit has already been used"
        );
        
        // We are still in the committing period & the commit is new so add it
        voteCommits.push(voteCommit);
        voteStatuses[voteCommit] = "Committed";
        numberOfVotesCast++;

        emit NewVoteCommit(
            voteCommit
        );
    }
    
    function revealVote(string vote, bytes32 voteCommit) public {
        // FIRST: Verify the vote & commit is valid
        bytes memory bytesVoteStatus = bytes(voteStatuses[voteCommit]);
        if (bytesVoteStatus.length == 0) {
            revert("A vote with this voteCommit was not cast.");
        } else if (bytesVoteStatus[0] != "C") {
            revert("This vote was already revealed.");
        }

        if (voteCommit != keccak256(abi.encodePacked(vote))) {
            revert("Vote hash does not match vote commit.");
        }
        
        // NEXT: Count the vote!
        bytes memory bytesVote = bytes(vote);
        if (bytesVote[0] == "1") {
            votesForChoice1 = votesForChoice1 + 1;
            emit NewVoteReveal(voteCommit, choice1);
        } else if (bytesVote[0] == "2") {
            votesForChoice2 = votesForChoice2 + 1;
            emit NewVoteReveal(voteCommit, choice2);
        } else {
            revert("Vote could not be read! Votes must start with the ASCII character `1` or `2`");
        }
        voteStatuses[voteCommit] = "Revealed";
    }
    
    function getWinner() 
        public 
        view 
        onlyAfterCommitPhase
        onlyWhenAllVotesAreCounted 
        returns (string) 
    {    
        if (votesForChoice1 > votesForChoice2) {
            return choice1;
        } else if (votesForChoice2 > votesForChoice1) {
            return choice2;
        } else if (votesForChoice1 == votesForChoice2) {
            return "It was a tie!";
        }
    }

    function getVoteCommitsArray() public view returns (bytes32[]) {
        return voteCommits;
    }
}