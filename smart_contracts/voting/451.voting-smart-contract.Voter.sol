//written by Ujjwal Prashant 

pragma solidity >=0.7.0 <0.9.0;


contract Ballot {
    //Voter here is a data type for voters is that different account holders who will vote 
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // this is for the person has voted or not 
        address delegate; // person delegated to and this will be empty if it has no delegate 
        uint vote;   // this is for the index of array whom the person wants to vote
    }

    struct Proposal {
       
        string name;   //taking name as a string  here for example (but bytes 32 will take less space and less gas fee which we can do it in future
        uint voteCount; // how much votes the Proposal has got (initially it will be 0)
    }
    

    address public chairperson;//address is a data type in solidity 

    mapping(address => Voter) public voters;// we are maping address of a voter with voter struct properties like weight delegate ....

    Proposal[] public proposals;//making Proposal array and name it proposals
    

  // constructor runs only for one time and here memory specifies that it does not get stored permanently
    constructor(string[] memory proposalNames) {
        chairperson = msg.sender; //msg.sender is the address of the person who has made this contract stored in chairperson variable 
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
           //from outside we got only proposals name but we have to know how many vote they got so we name a new Proposal struct where we also stored no. of votes count along with name.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
  //this function should be used only by chairperson otherwise it will not run 
    function giveRightToVote(address voter) public {
        //require means that the condition must be true otherwise it will not run below code
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

  //delegate function if we want to give our voting rights to other person
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");//here cchecking if sender has voted or not
        require(to != msg.sender, "Self-delegation is disallowed.");//here cchecking if sender is delegating to himself or not

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

           //this loop is very essential as here we are changing "to" to the person whom everyone wants to give voting right 
           
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight
            delegate_.weight += sender.weight;
        }
    }

  //giving all votes to the person we want to 
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }
   //returns wining proposal index of array where it is
    function winningProposal() public view
            returns (uint)
    {
        uint winningProposal_;
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
        return winningProposal_;
    }

    //this will gove winner name but first we will have to find wining propal_ as a index to find this
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}
