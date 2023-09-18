// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract Voting {
    // Keep track of the states of the votes
    enum VoteStates {Absent, Yes, No}

    struct Decision {
        address creator;
        string decision;
        uint yesCount;
        uint noCount;
        mapping (address => VoteStates) voteStates;
    }
    // An array of decisions
    Decision[] public decisions;

    function decisionCount() external view returns(uint) {
      return decisions.length;
    }

    event DecisionCreated(uint);
    event VoteCast(uint, address indexed);

    mapping(address => bool) voters;

    // you have to provide an array of specified addresses when you're deploying
    // only those contracts will be allowed to vote
    // max is 10 as specified in task specifications; like so
    // ["address1", "address2", "address3"]
    constructor(address[] memory _voters) {
        if (_voters.length <= 10) {
            for(uint i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
        }
        
        voters[msg.sender] = true;
    }

    function newDecision(string calldata _decision) external {
        require(voters[msg.sender]);
        emit DecisionCreated(decisions.length);
        Decision storage decision = decisions.push();
        decision.creator = msg.sender;
        decision.decision = _decision;
    }

    function castVote(uint _decisionId, bool _supports) external payable {
        require(voters[msg.sender]);
        Decision storage decision =decisions[_decisionId];

        // clear out previous vote
        if(decision.voteStates[msg.sender] == VoteStates.Yes) {
            decision.yesCount--;
        }
        if(decision.voteStates[msg.sender] == VoteStates.No) {
            decision.noCount--;
        }

        // add new vote
        if(_supports) {
            decision.yesCount++;
        }
        else {
            decision.noCount++;
        }

        // we're tracking whether or not someone has already voted
        // and we're keeping track as well of what they voted
        decision.voteStates[msg.sender] = _supports ? VoteStates.Yes : VoteStates.No;

        emit VoteCast(_decisionId, msg.sender);
    }
}