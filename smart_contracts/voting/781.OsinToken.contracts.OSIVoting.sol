// contracts/OSIVoting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GovToken.sol";
import "./RewToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OSIVoting is Ownable {

    struct Article {
        address writer;
        string url;
    }

    string public constant name = "OSI Voting";

    // 2 days for nominations
    uint public constant seconds_for_nominations = 172800;
    // 5 days for voting
    uint public constant seconds_for_voting = 432000;
    // number of votes given per goverance token
    uint256 public constant goverance_votes = 1000;
    // number of reward tokens given per winner
    uint256 public constant winner_tokens = 1000;

    // end of last voting period
    uint public startTime;

    GovToken public goverance;
    RewToken public rewards;

    // record of past winners
    Article[] public winners;

    // articles to be voted on this week
    Article[] public nominees;

    // nominations made by each address
    address[] nominators;
    mapping(address => uint256) nominationsMade;

    // number of votes cast by each address
    address[] voters;
    mapping(address => uint256) votesCast;

    // cumulative votes for each nominee
    uint256[] public voteCounts;

    constructor(uint256 _supply, uint _start) {
        goverance = new GovToken(msg.sender, _supply);
        rewards = new RewToken();
        startTime = _start;
    }

    event Nominate(address indexed _nominator, address indexed _writer, string _url);
    event Vote(address indexed _voter, string _url, uint256 _amount);
    event Winner(address indexed _writer, string _url);

    function setStartTime(uint _time) public onlyOwner {
        startTime = _time;
    }

    function nomineesWriter(uint _index) public view returns (address) {
        return nominees[_index].writer;
    }

    function nomineesUrl(uint _index) public view returns (string memory) {
        return nominees[_index].url;
    }

    function nomineesLength() public view returns (uint) {
        return nominees.length;
    }

    function winnersWriter(uint _index) public view returns (address) {
        return winners[_index].writer;
    }

    function winnersUrl(uint _index) public view returns (string memory) {
        return winners[_index].url;
    }

    function winnersLength() public view returns (uint) {
        return winners.length;
    }

    function nominationsEnds() public view returns (uint) {
        return startTime + seconds_for_nominations;
    }

    function votingEnds() public view returns (uint) {
        return startTime + seconds_for_nominations + seconds_for_voting;
    }

    function goveranceTransfer(address _from, address _to, uint256 _amount) external {
        require(msg.sender == address(goverance));

        uint256 nominationTransfer = _amount < nominationsMade[_from] ? _amount : nominationsMade[_from];
        nominationsMade[_from] -= nominationTransfer;
        nominationsMade[_to] += nominationTransfer;

        uint256 voteTransfer = goverance_votes * _amount < votesCast[_from] ? goverance_votes * _amount : votesCast[_from];
        votesCast[_from] -= voteTransfer;
        votesCast[_to] += voteTransfer;
    }

    function rewardsTransfer(address _from, address _to, uint256 _amount) external {
        require(msg.sender == address(rewards));

        uint256 voteTransfer = _amount < votesCast[_from] ? _amount : votesCast[_from];
        votesCast[_from] -= voteTransfer;
        votesCast[_to] += voteTransfer;
    }

    function votesRemaining(address _voter) public view returns (uint256) {
        return goverance_votes * goverance.balanceOf(_voter) + rewards.balanceOf(_voter) - votesCast[_voter];
    }

    function canNominate() public view returns (bool) {
        return nominationsMade[msg.sender] < goverance.balanceOf(msg.sender) && block.timestamp > startTime && block.timestamp <= startTime + seconds_for_nominations;
    }

    function submitNomination(address _writer, string calldata _url) public returns (bool) {
        require(nominationsMade[msg.sender] < goverance.balanceOf(msg.sender), "too many nominations");
        require(block.timestamp > startTime, "too early");
        require(block.timestamp <= startTime + seconds_for_nominations, "too late");
        require(!alreadyNominated(_url), "already nominate");

        nominationsMade[msg.sender] += 1;
        nominees.push(Article(_writer, _url));
        nominators.push(msg.sender);
        voteCounts.push();

        emit Nominate(msg.sender, _writer, _url);
        return true;
    }

    function canVote() public view returns (bool) {
        return votesRemaining(msg.sender) > 0 && block.timestamp > startTime + seconds_for_nominations && block.timestamp <= startTime + seconds_for_nominations + seconds_for_voting;
    }

    function castVotes(uint _index, uint256 _amount) public returns (bool) {
        require(votesRemaining(msg.sender) >= _amount, "too few remaining");
        require(_index < nominees.length, "invalid nominee");
        require(block.timestamp > startTime + seconds_for_nominations, "too early");
        require(block.timestamp <= startTime + seconds_for_nominations + seconds_for_voting, "too late");

        votesCast[msg.sender] += _amount;
        voteCounts[_index] += _amount;
        voters.push(msg.sender);

        emit Vote(msg.sender, nominees[_index].url, _amount);
        return true;
    }

    function updateWinner() public returns (bool) {
        if (block.timestamp > startTime + seconds_for_nominations + seconds_for_voting) {
            if (nominees.length > 0) {
                uint index = 0;
                for (uint i = 1; i < nominees.length; i++) {
                    if (voteCounts[i] > voteCounts[index]) {
                        index = i;
                    }
                }
                Article memory winner = nominees[index];

                winners.push(winner);
                rewards.mint(winner.writer, winner_tokens);
                emit Winner(winner.writer, winner.url); 
            }
           
            resetVoting();
            return true;
        }
        return false;
    }

    function resetVoting() private {
        delete nominees;

        for (uint i = 0; i < nominators.length; i++) {
            delete nominationsMade[nominators[i]];
        }
        delete nominators;

        for (uint i = 0; i < voters.length; i++) {
            delete votesCast[voters[i]];
        }
        delete voters;

        delete voteCounts;

        startTime += seconds_for_nominations + seconds_for_voting;
    }

    function alreadyNominated(string calldata _url) private view returns (bool) {
        bytes32 hashVal = keccak256(bytes(_url));
        for (uint i = 0; i < nominees.length; i++) {
            if (hashVal == keccak256(bytes(nominees[i].url))) {
                return true;
            }
        }
        return false;
    }
    
}
