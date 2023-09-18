pragma solidity ^0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/introspection/SupportsInterface.sol";

contract Governor is SupportsInterface {
    using SafeMath for uint;
    using Address for address;

    enum State { Created, Proposal, Active }
    State public state;

    address public owner;
    uint public quorum;
    uint public votingPeriod;
    uint public votingDelay;
    uint public proposalThreshold;
    address public _executor;
    mapping(bytes32 => bool) public votes;
    mapping(bytes32 => address) public proposalTo;
    mapping(bytes32 => uint) public proposalEnd;

    constructor(uint _quorum, uint _votingPeriod, uint _votingDelay, uint _proposalThreshold, address _executor) public {
        owner = msg.sender;
        quorum = _quorum;
        votingPeriod = _votingPeriod;
        votingDelay = _votingDelay;
        proposalThreshold = _proposalThreshold;
        _executor = _executor;
        state = State.Created;
    }

    function getVotes(bytes32 proposalId) public view returns (bool) {
        return votes[proposalId];
    }

    function propose(bytes32 proposalId, address destination) public {
        require(state == State.Created || state == State.Active, "Governor is not in a propose state");
        require(proposalEnd[proposalId] == 0, "Proposal already exists");
        require(destination != address(0), "Cannot propose to address 0");
        require(msg.sender == owner, "Only the owner can propose");
        proposalTo[proposalId] = destination;
        proposalEnd[proposalId] = now.add(votingPeriod);
        state = State.Proposal;
    }

    function cancel(bytes32 proposalId) public {
        require(state == State.Proposal, "Governor is not in a proposal state");
        require(proposalEnd[proposalId] != 0, "Proposal does not exist");
        require(msg.sender == owner, "Only the owner can cancel a proposal");
        delete proposalTo[proposalId];
        delete proposalEnd[proposalId];
        state = State.Created;
    }

    function vote(bytes32 proposalId, bool support) public {
        require(state == State.Proposal, "Governor is not in a proposal state");
        require(proposalEnd[proposalId] != 0, "Proposal does not exist");
        require(now > proposalEnd[proposalId].add(votingDelay), "Voting period has not yet passed");
        votes[proposalId] = support;
    }

    function execute(bytes32 proposalId) public {
        require(state == State.
