pragma solidity ^0.4.17;

//  owned
contract owned {
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function owned() public {
    owner = msg.sender;
  }
}


//  mortal
contract mortal is owned {
  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}


//  MyWallet
contract MyWallet is mortal {

  struct Proposal {
    address from;
    address to;
    uint value;
    string reason;
    bool sent;
  }

  uint private proposalCounter;
  mapping (uint => Proposal) private proposals;

  //  events
  event LogReceivedFunds(address indexed _from, uint _amount);
  event LogProposalReceived(uint indexed _id, address indexed _from, address indexed _to, string _reason);
  event LogProposalConfirmed(address indexed _from, address indexed _to, string _reason);

  function MyWallet() payable public {

  }

  function() public payable {
    if(msg.value > 0) {
      LogReceivedFunds(msg.sender, msg.value);
    }
  }

  function confirmProposal(uint _proposalId) public onlyOwner returns (bool) {
    Proposal storage proposal = proposals[_proposalId];

    if (proposal.from != address(0) && proposal.to != address(0)) {
      if (!proposal.sent) {
        proposal.sent = true;
        proposal.to.transfer(proposal.value);
        LogProposalConfirmed(proposal.from, proposal.to, proposal.reason);

        return true;
      }
    }
  }

  function spendMoneyOn(address _to, uint _value, string _reason) public returns (uint proposal_id) {
    if(msg.sender == owner) {
      _to.transfer(_value);
    } else {
      proposalCounter++;
      proposals[proposalCounter] = Proposal(msg.sender, _to, _value, _reason, false);
      proposal_id = proposalCounter;

      LogProposalReceived(proposalCounter, proposals[proposalCounter].from, proposals[proposalCounter].to, proposals[proposalCounter].reason);
    }
  }
}
