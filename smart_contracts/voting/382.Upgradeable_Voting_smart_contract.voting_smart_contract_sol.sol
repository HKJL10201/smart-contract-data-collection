// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;

/*
Anyone can submit a proposal
- a proposal only contains an id (why?)

The owner of the smart contract can give Voting rights
- How will we identify users?

Users with voting rights can vote on the proposal
Contains a function that calculates the winner 

remember: mappings cannot be iterated, think how you need the data
bonus: have a deadline --> how to define this? 
*/

abstract contract Owner {

    address public owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
} 
contract Voting is Owner{

    //map van proposal id naar aantal stemmen
    mapping(uint => uint ) proposals; 
    uint[] proposalsIds;

    // bijhouden wie die gestemd heeft
    // map van users address naar boolean
    // True: gebruiker mag stemmen
    // false: gebuiker mag niet stemmen
    mapping(address =>  bool) voterRights;

    event ProposalVoted(uint proposalId, uint votes, address voter);

    modifier canVote(){
        require(voterRights[msg.sender], "You may not vote");//de person die de functie aanroept is de ene die wilt stemmen
        _;

    }

    function vote(uint proposalId) public canVote{
        proposals[proposalId]++;//gaan registeren dat het gestemd geweest is 
        voterRights[msg.sender] = false; // om te vermijden dat de gebruiker kan meerdere keer stemmen

        emit ProposalVoted(proposalId, proposals[proposalId], msg.sender);
    }


    // aan mensen stemrecht geven 
    function giveVoterRights(address[] memory voters) public {  // als we de functie aanroepen wat geven we aan de functie 
                                        // we kunnen mensen aan de hand van een address [] identificeren
        for( int i = 0; i < voters.length; i++){
            voterRights[voters[i]] = true;
        }
    }

    function addProposals(uint[] memory _proposalsIds) public {  // proposals toe te voegen
        for(uint i= 0; i< _proposalIds.length; i++){
            proposalIds.push(_proposalIds[i]);
        }
    }

    function calculateWinner() public view returns(uint proposalId){
        uint winningProposal = proposalIds[0];
        uint winningProposalVotes;
        for(uint i = 0; i < proposalId.length; i++){
            uint currentProposalVotes = proposals[proposalIds[i]];
            if(currentProposalVotes > winningProposalVotes){
                winningProposalVotes = currentProposalVotes;
                winningProposal = proposalIds[i];
            }
        }
        return winningProposal;
    }


}

