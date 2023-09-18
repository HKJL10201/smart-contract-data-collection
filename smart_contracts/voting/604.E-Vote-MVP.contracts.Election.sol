pragma solidity ^0.4.18;

contract Election {

    // Represents a voter.
    struct Voter {
        bool voted;
        bytes32 bucket;
    }

    // Represents a candidate.
    struct Candidate {
        bytes32 name;
        bytes32 bucket;
        uint32 votes;
    }

    // voter -> Voter representation that they can vote for.
    mapping(bytes32 => Voter) public voterData;

    // candidate name -> data associated with that candidate.
    mapping(bytes32 => Candidate) public candidateTable;

    // bucket -> candidate names in that bucket.
    mapping(bytes32 => bytes32[]) public candidatesInBucket;

    // list of voters
    bytes32[] public voters;

    // list of candidates
    bytes32[] public candidates;

    // number of voters
    uint256 public voterCount;

    // number of candidates
    uint256 public candidateCount;

    // indicates if the election is closed.
    bool public closed;

    // the person who created the contract.
    address public electionOfficial;

    // @notice creates a new election with registered voters and the candidates that the voters can vote for.
    // @param _voters list of voters where voter is a hash(?) of the person voting, determined beforehand(?).
    // @param _bucket corresponding "bucket" that the voter can vote within.
    // @param _candidates list of candidates who are part of the election
    // @param _candidateBucket the 
    constructor(
        bytes32[] _voters, 
        bytes32[] _bucket, 
        bytes32[] _candidates,
        bytes32[] _candidateBucket
    )
        public
    {
        if (_voters.length != _bucket.length || _candidates.length != _candidateBucket.length) {
            return;
        }
        electionOfficial = msg.sender;
        voters = _voters;
        candidates = _candidates;
        voterCount = _voters.length;
        candidateCount = _candidates.length;

        for (uint i = 0; i < _candidates.length; i++) {
            Candidate memory candidate = Candidate(_candidates[i], _candidateBucket[i], 0);
            candidateTable[_candidates[i]] = candidate;

            candidatesInBucket[_candidateBucket[i]].push(_candidates[i]);
        }

        // Create new voters and add to contract
        for (i = 0; i < _voters.length; i++) {
            Voter memory voter = Voter(false, _bucket[i]);
            voterData[_voters[i]] = voter;
        }
    }

    // @notice Can be called by any address.
    // @param hash(?) of the person voting, determined beforehand(?).
    // @param candidate is the candidate "id" to which the voter is voting for.
    // @return true if successful, false otherwise.
    function vote(bytes32 voter, bytes32 candidate) public returns (bool) {
        if (closed || voterData[voter].voted || voterData[voter].bucket == "") {
            return false;
        }
        
        // Trying to vote for wrong bucket.
        if (voterData[voter].bucket != candidateTable[candidate].bucket) {
            return false;
        }

        // Record vote.
        candidateTable[candidate].votes++;
        voterData[voter].voted = true;
        
        return true;
    }

    // @notice The Election Official is able to close the election. (Could be later done by time, not official).
    //         Also gives results of the winner of a particular bucket group.
    // @param _bucket the bucket that you want to know the result of.
    // @return _winner the "id" of the candidate who is deemed the winner.
    // @return _votes the # of votes for the winning candidate.
    // function close(bytes32 _bucket) public returns (bytes32 _winner, uint32 _votes) {
    //     if (msg.sender == electionOfficial) {
    //         Candidate storage candidate = candidateTable[candidatesInBucket[_bucket][0]];

    //         _winner = candidate.name;
    //         _votes = candidate.votes;

    //         // count votes and return result
    //         for (uint i = 1; i < candidatesInBucket[_bucket].length; i++) {
    //             candidate = candidateTable[candidatesInBucket[_bucket][i]];

    //             if (candidate.votes > _votes) {
    //                 _winner = candidate.name;
    //                 _votes = candidate.votes;
    //             }
    //         }

    //         closed = true;
    //     }
    // }

    function closeElection() public returns (bool) {
        closed = true;
        return closed;
    }
}

// Can use require() for checks
