// SPDX-License-Identifier: GPL-3.0

contract Election{

    struct Voter{
        uint weight;
        uint8 vote;
        bool isVoted;
    }

    address public admin;
    mapping(address=>Voter) voters;
    uint[5] proposals;


    constructor() public {
        admin = msg.sender;
        voters[admin].weight=1;
        voters[admin].isVoted=false;
    }


    function Register(address toVoter, address adminAddress) public{

        if(voters[toVoter].isVoted || adminAddress!=admin) revert();
        voters[toVoter].isVoted=false;
        voters[toVoter].weight=1;

    }

    function Vote(uint8 proposal, address voterAddress) public {
        Voter storage sender = voters[voterAddress];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.isVoted, "Already voted.");
        require(proposal<=proposals.length, "Out of range");
        sender.isVoted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal] += sender.weight;
    }

    function checkVoted(address voterAddress) public view {

        Voter storage sender = voters[voterAddress];
        require(!sender.isVoted, "Already voted.");
        require(sender.weight != 0, "Has no right to vote");

    }

    function Winner() public view returns (uint _winning){
        uint winningVoteCount = 0;
        for(uint i=0;i<5;i++){
            if(proposals[i]>winningVoteCount)
            {
                winningVoteCount=proposals[i];
                _winning=i;
            }
        }
    }

}