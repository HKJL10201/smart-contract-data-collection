// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;
pragma experimental ABIEncoderV2;

contract VotingBase {
    /// @notice different stages in the election
    enum ElectionStage {
        NOT_RUNNING,
        AWAITING_CANDIDATE_LIST,
        AWAITING_VOTER_LIST,
        RUNNING,
        REVEALING
    }

    /// @notice different stages in the voter
    enum VoterStage {
        REGISTERED,
        SIGNED_UP,
        VOTED
    }

    /// @notice stores information about the candidate
    struct Candidate {
        address addr;
        uint64 votes;
        uint64 index;
    }

    /// @notice stores information about the voter
    struct Voter {
        address addr;
        uint64 index;
        VoterStage stage;
    }

    mapping(uint64 => Candidate) indexToCandidate;
    mapping(uint64 => Voter) internal indexToVoter;

    uint64 internal numCandidates;
    uint64 internal numVoters;
    uint64 internal nonce;
    address payable public owner;
    ElectionStage public electionStage;

    /// @dev base class constructor
    constructor() {
        owner = payable(msg.sender);
        numCandidates = 0;
        numVoters = 0;
        electionStage = ElectionStage.NOT_RUNNING;
        nonce = 0;
    }

    /// @dev helper function to generate random numbers
    /// @param maxNumber maximum value to generate
    /// @param minNumber minimum value to generate
    /// @return amount random number in range [minNumber, maxNumber]
    function random(uint64 maxNumber, uint64 minNumber)
        internal
        returns (uint256 amount)
    {
        amount =
            uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
            ) %
            (maxNumber - minNumber);
        amount = amount + minNumber;
        nonce++;
        return amount;
    }

    /// @dev internal function to convert uint to string
    /// @param _i number of convert
    /// @return _uintAsString the number as a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @dev internal function to convert uint256 to uint64 by trimming the bits
    /// @param _a uint256 number
    /// @return uint64 the trimmed value
    function convert256to64(uint256 _a) internal pure returns (uint64) {
        return uint64(_a);
    }

    /// @notice adds candidate to the election
    /// @param addr address of the candidate
    function addCandidate(address addr) public {
        require(
            electionStage == ElectionStage.AWAITING_CANDIDATE_LIST,
            "Not accepting candidates right now"
        );
        numCandidates++;
        indexToCandidate[numCandidates] = Candidate(addr, 0, numCandidates);
        emit CandidateAdded(numCandidates, addr);
    }

    /// @notice adds voter to the election
    /// @param addr address of the voter
    function addVoter(address addr) public {
        require(
            electionStage == ElectionStage.AWAITING_VOTER_LIST,
            "Not accepting voters right now"
        );
        numVoters++;
        indexToVoter[numVoters] = Voter(addr, numVoters, VoterStage.REGISTERED);
        emit VoterAdded(numVoters, addr);
    }

    /// @notice returns the number of candidates
    function getNumberOfCandidates() public view returns (uint64) {
        return numCandidates;
    }

    /// @notice returns the number of voters
    function getNumberOfVoters() public view returns (uint64) {
        return numVoters;
    }

    /// @notice begins candidate sign up stage
    function acceptCandidates() public {
        require(
            electionStage == ElectionStage.NOT_RUNNING,
            "Election already running"
        );
        electionStage = ElectionStage.AWAITING_CANDIDATE_LIST;
        emit CandidateSignUpStart();
    }

    /// @notice begins voter sign up stage
    function acceptVoters() public {
        require(
            electionStage == ElectionStage.AWAITING_CANDIDATE_LIST,
            "Candidates not registered till now"
        );
        electionStage = ElectionStage.AWAITING_VOTER_LIST;
        emit VoterSignUpStart();
    }

    /// @dev modifier for `startElection` API
    modifier startElectionModifier() {
        require(
            electionStage == ElectionStage.AWAITING_VOTER_LIST,
            "Voters not registered yet"
        );
        _;
    }

    /// @dev modifier for `startReveal` API
    modifier startRevealModifier() {
        require(
            electionStage == ElectionStage.RUNNING,
            "Election not running at the moment!"
        );
        _;
    }

    /// @dev modifier for `endElection` API
    modifier endElectionModifier() {
        require(
            electionStage == ElectionStage.REVEALING,
            "Reveal not started yet!"
        );
        _;
    }

    /// @dev modifier for `clearData` API
    modifier clearDataModifier() {
        require(
            electionStage == ElectionStage.NOT_RUNNING,
            "Election in progress!"
        );
        for (uint64 i = 1; i <= numVoters; i++) {
            delete (indexToVoter[i]);
        }
        for (uint64 i = 1; i <= numCandidates; i++) {
            delete (indexToCandidate[i]);
        }
        _;
        numCandidates = 0;
        numVoters = 0;
    }

    /// @dev base class function for `startElection` API
    function startElection() public virtual startElectionModifier {}

    /// @dev base class function for `startReveal` API
    function startReveal() public virtual startRevealModifier {}

    /// @dev base class function for `endElection` API
    function endElection() public virtual endElectionModifier {}

    /// @dev base class function for `clearData` API
    function clearData() public virtual clearDataModifier {}

    /// @dev base class function for `getWinner` API
    function getWinner() public view virtual returns (uint64) {}

    /// @notice returns the status of the election
    function getElectionStatus() public view returns (uint256) {
        if (electionStage == ElectionStage.NOT_RUNNING) {
            return 0;
        } else if (electionStage == ElectionStage.AWAITING_CANDIDATE_LIST) {
            return 1;
        } else if (electionStage == ElectionStage.AWAITING_VOTER_LIST) {
            return 2;
        } else if (electionStage == ElectionStage.RUNNING) {
            return 3;
        } else if (electionStage == ElectionStage.REVEALING) {
            return 4;
        }
        return 10;
    }

    /// @notice records start of candidate sign up
    event CandidateSignUpStart();

    /// @notice records candidate being added
    /// @param candidateID ID of the candidate
    /// @param candidateAddress address of the candidate
    event CandidateAdded(uint64 candidateID, address candidateAddress);

    /// @notice records start of voter sign up
    event VoterSignUpStart();

    /// @notice records voter being added
    /// @param voterID ID of the voter
    /// @param voterAddress address of the voter
    event VoterAdded(uint64 voterID, address voterAddress);

    /// @notice declared votes for a candidate in an election
    /// @param candidateID ID of the candidate
    /// @param numVotes number of votes casted for the candidate
    event DeclareVotes(uint64 candidateID, uint64 numVotes);
}
