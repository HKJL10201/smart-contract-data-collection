// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/ElectionToken.sol";

contract Election {
    IERC20 internal electionToken;

    enum ELECTION_STATE {
        OPEN,
        CLOSED,
        COUNTING_VOTES
    }

    uint256[] votes;

    // Tracking each address's vote
    mapping(address => uint256) public addressToVote;
    // Tracking how much token an address should recieve
    mapping(address => uint256) public addressToTokenAmount;
    address[] participants;
    address owner;

    event Winner(uint256 _index, uint256 _voteNumber);

    ELECTION_STATE public election_state;
    uint256 startingTime;
    uint256 endingTime;

    constructor(address _electionToken) public {
        // Interface for our special token
        electionToken = IERC20(_electionToken);
        owner = msg.sender;
        election_state = ELECTION_STATE.CLOSED;
    }

    function startElection(uint256 _duration, uint256 _candidateNumbers)
        public
        onlyOwner
    {
        election_state = ELECTION_STATE.OPEN;
        // Array for tracking votes
        votes = new uint256[](_candidateNumbers);
        // Clearing the mapping for next uses
        address[] memory _participants = participants;
        for (uint256 index = 0; index < _participants.length; index++) {
            delete addressToVote[_participants[index]];
        }
        // Clearing the participants array
        delete participants;
        startingTime = block.timestamp;
        endingTime = startingTime + _duration;
    }

    function endElection() public onlyOwner {
        require(
            block.timestamp >= endingTime,
            "Election Duration not reached yet!"
        );
        election_state = ELECTION_STATE.COUNTING_VOTES;
        uint256 winnerIndex = 0;
        for (uint256 index = 1; index < votes.length; index++) {
            if (votes[index] > votes[index - 1]) {
                winnerIndex = index;
            }
        }
        emit Winner(winnerIndex, votes[winnerIndex]);
        election_state = ELECTION_STATE.CLOSED;
    }

    function vote(uint256 _vote) public payable {
        // Requires the election to be open
        require(election_state == ELECTION_STATE.OPEN, "Election not open!");
        // Requires the voter to have enough funds (0.5 ET)
        require(
            electionToken.balanceOf(msg.sender) > 500000000000000000,
            "You don't have enough funds!"
        );
        // Requires the vote to be in a valid range
        require(_vote < votes.length, "Invalid Vote");
        // Takes 0.5 ET as voting fee
        electionToken.transferFrom(
            payable(msg.sender),
            address(this),
            500000000000000000
        );
        // Maps the address to their vote
        addressToVote[msg.sender] = _vote;
        // Adds the voter address to the array of participants
        participants.push(msg.sender);
        // Adds vote amount based on token balance of voter
        votes[_vote] += electionToken.balanceOf(msg.sender);
    }

    function playGame(uint256 _answer, address _sender) public {
        // Some game can be designed in which the winner would recieve ET, in this case we assume there is a game with 8459 as the correct answer.
        require(_answer == 8459, "Wrong answer, no tokens for you!");
        // Requires the balance of contract to be more than 1 ET.
        require(
            electionToken.balanceOf(_sender) > 1000000000000000000,
            "No more token's available"
        );
        addressToTokenAmount[msg.sender] += 1000000000000000000;
    }

    function getToken(address _sender) public {
        electionToken.transferFrom(
            _sender,
            msg.sender,
            addressToTokenAmount[msg.sender]
        );
    }

    // Function which would transfer every token in the contract(which has been collected from the votes) to the owner of the contract
    function clearContract() public payable onlyOwner {
        uint256 balance = electionToken.balanceOf(address(this));
        electionToken.transfer(msg.sender, balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
