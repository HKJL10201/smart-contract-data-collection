// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;
contract Voting{
    address Owner;
  struct Proposal{
    string title;
    uint id;
    uint votecount;
    address proposedby;
    mapping(address=>voter) voters;
  }
  
  Proposal [] public  Proposals;
  
  struct voter{
    bool voted;
  } 
  
  uint count =0;
  event Proposalcreated(address  indexed creator);
  event Vote(address  indexed Voter);
  
  modifier onlyowner{
      require(msg.sender == Owner,"Only owner can add the proposal");
      _;
  }
  constructor () public {
      Owner = msg.sender;
  }
  function addproposal(string memory _title) public  onlyowner{
    Proposal memory p ;

    p.title = _title;
    p.votecount = 0;
    p.proposedby = msg.sender;
    p.id = count;
    Proposals.push(p);
    count++;

    emit Proposalcreated(msg.sender);

  }
  function gettotalProposal() public view returns(uint ){
       return Proposals.length;
  }
  function getProposal( uint id) public view returns(string memory title , uint Id, uint votecount, address proposedby ){
      Proposal storage p = Proposals[id];
      return(p.title, p.id, p.votecount, p.proposedby); 
  }
  
  function vote(uint id) public{
    Proposals[id].votecount += 1;
    Proposals[id].voters[msg.sender].voted = true;
    emit Vote(msg.sender);
  }
  function hasvoted(uint256 proposalId, address voterAddress) public view returns (bool)
  {
     Proposal storage p = Proposals[proposalId];
        return p.voters[voterAddress].voted;
    


  }
}