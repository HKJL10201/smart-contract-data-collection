pragma solidity ^0.8.4;

/*
A voting system that reward people participating the most by giving them more more power.
*/

contract voteBernaille {


address public chairman; // THe chairman of the vote
uint[] public proposal; // The array of all the proposal
uint numberOfProposal; // For how many proposal are we going to vote

struct Voter {
    address addr;
    uint256 duration; // since when the user has been registered.
    uint numberOfVote; // How many time the user voted
    bool allowedToVoted;
    bool[] votedForProposition;
    uint weight; // Each vote give + 100 + weight to a  score
    
    
}

    mapping(address => Voter) public peopleVotingMapping;



// Check if the proposalNumber for which the personn wants to vote exist
modifier requireProposal(uint nbr){
    require(nbr<=numberOfProposal);
    _;
}

//check if the person haven't voted for the proposal yet
modifier requireVotedForProposal(uint nbr){
    require(!peopleVotingMapping[msg.sender].votedForProposition[nbr]);
    _;
}

// Check if the person is the chairman
modifier onlyChairman(address adressPersonne) // Chech if the personne is valid. 
    { require(adressPersonne == chairman);
      _;
    }


// Check if the person is allow to vote. 
// Is usefull in the case if we want to keep someone register but we don't want him to vote anymore.
modifier allowedToVoted(address personneToBeChecked) {
    require(peopleVotingMapping[msg.sender].allowedToVoted);
    _;
    
}

event endOContract();

// Event when someone voted.
event infoVoter(address adre);

event oneVoteHasBeenMade(); 


constructor() {
    
    chairman = msg.sender;
    numberOfProposal = 3; // how many different proposal do we want
    for(uint i=0;i<numberOfProposal;i++){
        proposal.push(0);
    }
    
}


// I haven't code this function yet. Maybe later if there is any necessity
/*
function startVote(uint renvoieTest) public validPerson(msg.sender){
    emit endOContract();
*/

// Can only be used by the chairman. The function register people giving them the right to vote.
function registered(address adressToBeRegistered) public onlyChairman(msg.sender) {
    peopleVotingMapping[adressToBeRegistered].numberOfVote = 0;
    peopleVotingMapping[adressToBeRegistered].allowedToVoted = true;
    peopleVotingMapping[adressToBeRegistered].duration = block.timestamp;
    for(uint i=0; i<numberOfProposal;i++) peopleVotingMapping[adressToBeRegistered].votedForProposition.push(false);
    peopleVotingMapping[adressToBeRegistered].weight = 100; // At the beginning the voter have a 100 weigt. 
    
}



// Function that print some info on the voter
function printInfoVoter() public{
    emit infoVoter(msg.sender);

}


function vote(uint proposalNumber, bool infavor) allowedToVoted(msg.sender) public requireProposal(proposalNumber) requireVotedForProposal(proposalNumber){
    peopleVotingMapping[msg.sender].votedForProposition[proposalNumber] = true;

    //if the person is in favor of the proposal we add 1 to the proposal score otherwise we add -1.  
    if(infavor) proposal[proposalNumber] = proposal[proposalNumber] +  peopleVotingMapping[msg.sender].weight + peopleVotingMapping[msg.sender].numberOfVote * 10 ;
    else proposal[proposalNumber] -= 100 ;
    
    peopleVotingMapping[msg.sender].numberOfVote++; // increase this to know how many time the person voted 
    emit oneVoteHasBeenMade();

    
}

function winningProposal() public onlyChairman(msg.sender) returns(uint winningProposal){
    uint max = 0;
    uint winningProposal = 0;
    for(uint i=0;i<numberOfProposal;i++){
        if(proposal[i]>max) {
            max = proposal[i];
            winningProposal = i;
        }
    }
    
}





}// End of contract




