// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    
    struct Voter {
        uint vote;
        address votersAddress;
        bool authorized;
        bool voted;
    }

    struct Proposal {
        string name;
        uint totalVotes;
    }

    mapping(address => Voter) public voters; 
    Voter[] public votersArray;
    
    Proposal[] public proposals;

    function registerProposal(string memory _name) public {
        proposals.push(Proposal(_name, 0));
    }

    function registerVoter() public {
        require(voters[msg.sender].authorized == false, "You are already authorized");
        voters[msg.sender].authorized = true;
        votersArray.push(Voter(0, msg.sender, true, false));
    }

    function vote(uint _vote) public {
        require(_vote <= proposals.length);
        require(voters[msg.sender].voted == false && voters[msg.sender].authorized == true, "You either already voted or you are not authorized");
        proposals[_vote].totalVotes += 1;
        voters[msg.sender].vote = _vote;
    }

    function countVotes() public view returns(uint) {
        uint mostVotesIndex = 0;
        uint mostVotes = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].totalVotes > mostVotes) {
                mostVotes = proposals[i].totalVotes;
                mostVotesIndex = i;
            }
        }
        return mostVotesIndex;
    }

    function declareWinner() public view returns (string memory) {
        string memory name = proposals[countVotes()].name;
        return name;
    }

    function restartVoting(uint _value) public {
        for (uint i = 0; i < votersArray.length; i++) {
            address forAddress = votersArray[i].votersAddress; 
            voters[forAddress].vote = _value;
            voters[forAddress].authorized = false;
            voters[forAddress].voted = false;
        }
        delete proposals;
    }
}

