pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingMachine is Ownable {
    event CandidateVoted(bytes32 candidateId, address voter);
    event CandidateCreated(bytes32 candidateId);

    struct Candidate {
        bytes32 id;
        string name;
        bool exists;
    }

    mapping(bytes32 => Candidate) public candidates;
    mapping(bytes32 => address[]) public votes;
    mapping(address => bool) public voters;
    bytes32[] public candidateIds;

    function randomId(string memory _name) private pure returns (bytes32) {
        return keccak256(abi.encode(_name));
    }

    function createCandidate(string memory _name) external onlyOwner {
        bytes32 _id = randomId(_name);
        require(!candidates[_id].exists);
        candidates[_id] = Candidate(_id, _name, true);
        candidateIds.push(_id);
        emit CandidateCreated(_id);
    }

    function getCandidateName(bytes32 _id) public view returns (string memory) {
        return candidates[_id].name;
    }

    function vote(bytes32 _id) public {
        require(!voters[msg.sender], "already voted");
        voters[msg.sender] = true;
        votes[_id].push(msg.sender);
        emit CandidateVoted(_id, msg.sender);
    }

    function getVotes(bytes32 _id) public view returns (address[] memory) {
        return votes[_id];
    }

    function listCandidateIds() external view returns (bytes32[] memory) {
        return candidateIds;
    }
}
