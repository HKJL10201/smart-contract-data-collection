pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract VotingSystem {
    address owner;

    mapping(string => bytes32) candidateId;
    mapping(string => uint256) candidateVotes;

    string[] candidates;
    bytes32[] voters;

    event CandidateEnrolled(bytes32 candidateId);
    event CandidateVoted(string name);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyForEnrolledCandidates(string memory candidateName) {
        // TODO: Find out if this can be more efficient
        bool candidateExists = false;
        for (uint256 i = 0; i < candidates.length; i++) {
            candidateExists =
                keccak256(abi.encodePacked(candidates[i])) ==
                keccak256(abi.encodePacked(candidateName));
        }
        require(candidateExists, "The Candidate is not enrolled");
        _;
    }

    function enrollCandidate(
        uint256 id,
        string memory name,
        int256 age
    ) public {
        // TODO: validate that candidate doesn't already exist
        bytes32 candidateHashId = keccak256(abi.encodePacked(id, name, age));

        candidateId[name] = candidateHashId;
        candidateVotes[name] = 0;

        candidates.push(name);
        emit CandidateEnrolled(candidateHashId);
    }

    function vote(string memory candidateName)
        public
        onlyForEnrolledCandidates(candidateName)
    {
        bytes32 voterHash = keccak256(abi.encodePacked(msg.sender));

        for (uint256 i = 0; i < voters.length; i++) {
            require(
                voters[i] != voterHash,
                "You have already submited your vote before"
            );
        }

        candidateVotes[candidateName]++;
        voters.push(voterHash);
        emit CandidateVoted(candidateName);
    }

    function viewVotesByCandidate(string memory candidateName)
        public
        view
        returns (uint256)
    {
        return candidateVotes[candidateName];
    }

    function viewCandidates() public view returns (string[] memory) {
        return candidates;
    }

    function viewVotingResults() public view returns (string memory) {
        string memory results;

        for (uint256 i = 0; i < candidates.length; i++) {
            results = string(
                abi.encodePacked(
                    results,
                    ",",
                    candidates[i],
                    ": ",
                    uint2str(viewVotesByCandidate(candidates[i]))
                )
            );
        }

        return results;
    }

    function Winner() public view returns (string memory) {
        string memory winner = candidates[0];
        bool thereATie = false;
        for (uint256 i = 1; i < candidates.length; i++) {
            if (
                viewVotesByCandidate(winner) <
                viewVotesByCandidate(candidates[i])
            ) {
                winner = candidates[i];
                thereATie = false;
            } else {
                if (
                    viewVotesByCandidate(candidates[i]) ==
                    viewVotesByCandidate(winner)
                ) {
                    thereATie = true;
                }
            }
        }
        return (thereATie ? "There's a tie!" : winner);
    }

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
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}
