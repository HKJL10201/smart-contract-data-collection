//SPDX-License-Identifier:GPL-3.0
pragma solidity >0.6.99 <0.8.0;

contract Voting {
    struct Voter {
        bool voted;
        uint256 vote;
        bool right;
    }
    struct Candidate {
        bytes32 name;
        uint256 votecount;
    }
    address chairperson;
    Candidate[] public candidates;
    mapping(address=>Voter) public voters;//maaping address to the voter 
   
    constructor(bytes32[] memory candidatename ){ 
        chairperson = msg.sender;//address deploying the contract will be the chairperson 
        voters[chairperson].right = true; //voting right approved to the chairperson
        for (uint i=0;i< candidatename.length;i++) //candidate name stored in the stack 
    //Candidate({....}) creates temporary candidates object 
    {   candidates.push(Candidate({
        name:candidatename[i],
        votecount :0
    }));
    }
    }

    function voterregistration(address voter ) public  //view??
    {  require(msg.sender==chairperson,'Only chairperson can register' );//only chairperson can register the voter 

    require(!voters[voter].right,'Already registered !!!');//voter shouldnot be already registered

    require(!voters[voter].voted, ' Already voted!!!');//voter shouldnot have voted 

    voters[voter].right=true ;//right given to the voter 
       
}
    function vote(uint candidate) public {
        Voter storage sender = voters[msg.sender];

        require(sender.right );
        require(sender.voted ,'Already voted!!');
        sender.voted = true;
        sender.vote = candidate;
        candidates[candidate].votecount +=1; 
    }
    function winnercandidate() public view returns(bytes32 name) {
        uint winningvote =0;
        uint p_winner;
        for (uint p=0;p<candidates.length;p++){
            if(candidates[p].votecount>=winningvote){
                winningvote =candidates[p].votecount;
                p_winner = p;}}
                name = candidates[p_winner].name;
        

            } 
        }
    
    


    

