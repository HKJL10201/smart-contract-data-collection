pragma solidity ^0.4.24;

import "./Ownable.sol";

contract VoteFactory is Ownable {
    modifier ownerOfVote(uint256 _voteId) {
        require(voteToOwner[_voteId] == msg.sender);
        _;
    }
    modifier stateOf(uint256 _voteId, State _state) {
        require(votes[_voteId].state == _state);
        _;
    }

    event CreateVote(uint256 id, string question);
    event AddAnswer(uint256 voteId, bytes32 answers);
    event StartVote(uint256 id);
    event StopVote(uint256 id);

    enum State {
        Initial,
        Started,
        Stopped
    }

    uint256 constant MAX_VOTERS = 1e10;

    struct Vote {
        State state;
        string question;
        bytes32[] answers;
        address[] voters;

        mapping(uint256 => uint256) voterToAnswer;
    }

    Vote[] public votes;
    mapping(uint256 => address) public voteToOwner;
    mapping(address => uint256[]) public ownerToVotes;

    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    function createVote(string _question) public returns(uint256 voteId) {
        voteId = votes.push(Vote(State.Initial, _question, new bytes32[](0), new address[](0))) - 1;
        voteToOwner[voteId] = msg.sender;
        ownerToVotes[msg.sender].push(voteId);
        emit CreateVote(voteId, _question);
    }

    function createVote(string _question, bytes32[] _answers) public returns(uint256 voteId) {
        voteId = createVote(_question);
        addAnswers(voteId, _answers);
    }

    function addAnswer(uint256 _voteId, bytes32 _answer) public ownerOfVote(_voteId) {
        votes[_voteId].answers.push(_answer);
        emit AddAnswer(_voteId, _answer);
    }

    function addAnswers(uint256 _voteId, bytes32[] _answers) public ownerOfVote(_voteId) {
        for (uint256 i = 0; i < _answers.length; i++) {
            addAnswer(_voteId, _answers[i]);
        }
    }

    function voteAnswer(uint256 _voteId, uint256 _answerId) public view returns(bytes32) {
        return votes[_voteId].answers[_answerId];
    }

    function startVote(uint256 _voteId) external ownerOfVote(_voteId) {
        votes[_voteId].state = State.Started;
        emit StartVote(_voteId);
    }

    function stopVote(uint256 _voteId) external ownerOfVote(_voteId) stateOf(_voteId, State.Started) {
        votes[_voteId].state = State.Stopped;
        emit StopVote(_voteId);
    }

    function cast(uint256 _voteId, uint256 _answerId) external stateOf(_voteId, State.Started) returns(uint256) {
        require(votes[_voteId].voters.length < MAX_VOTERS, "Voters count must be lower MAX_VOTERS");

        uint256 voterId = getVoterId(_voteId);
        if (voterId < MAX_VOTERS) {
            _castVoter(_voteId, _answerId, voterId);
            return voterId;
        }

        voterId = votes[_voteId].voters.push(msg.sender) - 1;
        _castVoter(_voteId, _answerId, voterId);
        return voterId;
    }

    function _castVoter(uint256 _voteId, uint256 _answerId, uint256 _voterId) private {
        votes[_voteId].voterToAnswer[_voterId] = _answerId;
    }

    function getVoterId(uint256 _voteId) public view returns(uint256) {
        address[] storage voters = votes[_voteId].voters;
        for (uint256 i = 0; i < voters.length; i++)
            if (voters[i] == msg.sender) {
                return i;
            }

        return MAX_VOTERS + 1;
    }

    function results(uint256 _voteId) public view returns(bytes32) {
        Vote storage vote = votes[_voteId];
        uint256[] memory result = new uint256[](vote.answers.length);

        for (uint256 i = 0; i < vote.voters.length; i++) {
            result[vote.voterToAnswer[i]]++;
        }

        uint256 maxId = 0;
        uint256 max = result[0];

        for (i = 0; i < result.length; i++) {
            if (result[i] > max) {
                maxId = i;
                max = result[i];
            }
        }

        return vote.answers[maxId];
    }

    function isStopped(uint256 _voteId) external view returns(bool) {
        return votes[_voteId].state == State.Stopped;
    }

    /*
    * GETTERS
    */

    function getVote(uint256 _voteId) public view returns(State, string, bytes32[], int256[]) {
        Vote storage vote = votes[_voteId];
        int256[] memory res = new int256[](vote.answers.length);

        for (uint256 i = 0; i < vote.voters.length; i++) {
            res[vote.voterToAnswer[i]] += 1;
        }

        return (vote.state, vote.question, vote.answers, res);
    }

}
