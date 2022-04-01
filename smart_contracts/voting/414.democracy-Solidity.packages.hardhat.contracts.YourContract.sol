pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {
//Defining the structures the contract will contain
/**FFor this use case we have 2 structures: 
-Voter: Represent the person who will vote 
 Proposa;: Represent the purpose that people will vote for.

 */
  struct Voter{
    uint weight;
    bool voted;
    uint choice;
  }
  struct Proposal{
    uint numeberOfVotes;
  }
  mapping(address => Voter)voters; //Each voter structure has a address
  Proposal[] proposals;
  string public purpose = "Democracy contract";
  Phase public contractState;
  enum Phase{Init,Regs,Vote,Done}
  address chairperson;
  // constructor(uint numberOfProposals) { // the number of proposals that will start the contract
    constructor(){
      uint numOfProp=3;
      for(uint i=0;i<numOfProp;i++){
        proposals.push(Proposal(0));
      }
      chairperson=msg.sender;
    // what should we do on deploy?
  }
  //Generic function change state 
  function setState(Phase x) public{
    if(msg.sender != chairperson){
      revert("You are not allowed to do this");
    }
    if(contractState>x){
      revert("You can't go back in states ");
    }
  }
  function setPurpose(string memory newPurpose) public {
      purpose = newPurpose;
      console.log(msg.sender,"set purpose to",purpose);
      // emit SetPurpose(msg.sender, purpose);
  }
}
  