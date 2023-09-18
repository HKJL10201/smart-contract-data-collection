// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ballot {
    address public chairperson;

    //Custom type to represent single voter
    struct Voter {
        address delegate;
        uint vote; //index of proposals
        uint weight;
        bool voted;
    }

    //Custom type for one proposals
    struct Proposal {
        bytes32 name;
        uint voteCount;
    }

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor(bytes32[] memory proposalName) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalName.length; i++) {
            proposals.push(Proposal({name: proposalName[i], voteCount: 0}));
        }
    }

    function rightToVote(address _voter) external {
        require(msg.sender == chairperson);
        require(voters[_voter].weight == 0);
        require(voters[_voter].voted == false);

        voters[_voter].weight = 1;

    }

    function delegate(address _to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.voted == false);
        require(sender.delegate != _to);

        while (voters[_to].delegate != address(0)) {
            _to = voters[_to].delegate;

            require(_to != msg.sender, "Found loop in delegation");
        }

        Voter storage delegate_ = voters[_to];
        require(delegate_.weight > 0);
        sender.voted = true;
        sender.delegate = _to;

        if(!delegate_.voted){
            delegate_.weight += sender.weight;
        } else {
            proposals[delegate_.vote].voteCount += sender.weight;
        }

    }

    function vote(uint _proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0);
        require(sender.voted == false);

        sender.vote = _proposal;
        sender.voted = true;

        proposals[_proposal].voteCount += sender.weight;

    }

    function winningProposal() public view returns(uint winningProposal_) {
        uint winningVoteCount = 0;

        for(uint p=0; p < proposals.length; p++){
            if(proposals[p].voteCount > winningVoteCount){
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_){
        winnerName_ = proposals[winningProposal()].name;
    }


}
