pragma solidity >=0.4.22 <0.6.0;
contract SimpleVotingSystem {

    struct Voter {
        bool voted;
        bool approved_1;
        bool approved_2;
        uint8 vote;
    }

    string descriptionOfPoll
    string descriptionOfOption1
    string descriptionOfOption2
    address approver1;
    address approver2;
    uint256 endTime;
    mapping(address => Voter) voters;
    mapping(uint8 => uint256) voteCount;

    constructor(address _approver2, 
                string _descriptionOfPoll, 
                string _descriptionOfOption1,
                string _descriptionOfOption2) public {
        require(msg.sender != _approver2);
        approver1 = msg.sender;
        approver2 = approver2;
        voters[approver1].approved_1 = true;
        voters[approver1].approved_2 = true;
        voters[approver2].approved_1 = true;
        voters[approver2].approved_2 = true;
        
        descriptionOfPoll = _descriptionOfPoll;
        descriptionOfOption1 = _descriptionOfOption1;
        descriptionOfPotion2 = _descriptionOfOption2;
    }

    /* 
     * Approve voter both approver must approve before address can vote
     */
    function approveVoter(address voter) public {
        require(msg.sender == approver1 || msg.sender == approver2);
        if(msg.sender == approver1) {
            voters[voter].approved_1 = true;
            return;
        }
        
        if(msg.sender = approver2) {
            voters[voter].approved_2 = true;
            return;
        }
    }

    /* 
     * Disapprove voter to revoke voting permissions
     */    
    function disapproveVoter(address voter) public {
        require(msg.sender == approver1 || msg.sender == approver2);
        if(msg.sender == approver1) {
            voters[voter].approved_1 = false;
            return;
        }
        
        if(msg.sender = approver2) {
            voters[voter].approved_2 = false;
            return;
        }
    }

    /*
     * Vote for option 1 or 2. Any other values are not counted
     */
    function vote(uint8 option) public {
        require(voters[msg.sender].approved_1 && voters[msg.sender].aproved_2);
        Voter storage sender = voters[msg.sender];
        if (sender.voted || toProposal >= proposals.length) return;
        sender.voted = true;
        sender.vote = option;
        voteCount[toProposal] += 1;
    }

    /*
     * Return 1 or 2 if either option wins. Return -1 if draw
     */
    function winningProposal() public view returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        if(voteCount[1] > voteCount[2]) {
            return 1;
        }
        else if(voteCount[2] > voteCount[1]) {
            return 2;
        }
        else {
            return -1;
        }
    }
}

