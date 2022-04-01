// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BallotVote {

    struct Voter {
        bool voted;             
        uint weight;
        uint vote;
    }

    struct Proposal {
        bytes32 proposalName;   
        uint256 voteCount;      

    }

    Proposal[] public proposals;
    mapping(address => Voter) public voters;

    address public chairPerson;
    

    constructor(bytes32[] memory proposalNames) public {
        chairPerson = msg.sender;
        voters[chairPerson].weight = 1;

        for(uint256 i=0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                proposalName: proposalNames[i],
                voteCount: 0
            }));
        }

    }

    //function authenticate vorter
    function giveRightToVotet(address voter) public {
        require(msg.sender == chairPerson, 'Only the chairperson can give access to vote');
        require(!voters[voter].voted, 'The vorter has already voted');
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    //function for voting
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, 'Has no right to vote');
        require(!sender.voted,'Already voted');
        sender.voted = true;
        sender.vote = proposal;
        
        proposals[proposal].voteCount = proposals[proposal].voteCount + sender.weight;
    }

    function winningProposal() public view returns (uint _winningProposal) {
        uint winningVoteCount = 0;
        for(uint i=0; i < proposals.length; i++) {
            if(proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                _winningProposal = i;
            }
        }
    }

    function winningName() public view returns (bytes32 _winningName) {

        _winningName = proposals[winningProposal()].proposalName;
    }
}
    