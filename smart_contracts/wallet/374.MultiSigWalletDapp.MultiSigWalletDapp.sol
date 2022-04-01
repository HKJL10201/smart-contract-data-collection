pragma solidity ^0.4.20;

contract MultiSigWalletDapp {
struct proposal{
  uint value;
  mapping (address => uint) decisionFromSigners;
  uint noofApprovals;
  uint noOfDecisions;
}
mapping (address => proposal) submittedProposals;
address[] openProposals;
mapping (address => uint) contributorsMap;
address[] contributors;
address ownerOfContract;
bool activeForProposals = false;
uint initialTotalHoldings;
uint totalHoldings;
uint noOfContributors;
uint noOfOpenProposals;

function() payable public{
  require(activeForProposals==false);
  if(contributorsMap[msg.sender] == 0){
    contributors.push(msg.sender)
    noOfContributors++;
  }
  contributorsMap[msg.sender] = add(contributorsMap[msg.sender], msg.value);
   emit ReceivedContribution(msg.sender,msg.value);
}
constructor() public {
  ownerOfContract = msg.sender;
}
modifier isSigner(address _signer){
  require(_signer == 0xfA3C6a1d480A14c546F12cdBB6d1BaCBf02A1610|| _signer == 0x2f47343208d8Db38A64f49d7384Ce70367FC98c0 || _signer == 0x7c0e7b2418141F492653C6bF9ceD144c338Ba740);
  _;
}

function owner() external returns(address){
  ownerOfContract.transfer(address(this).balance);
}

event ReceivedContribution(address indexed _contributor, uint _valueInWei);

function endContributionPeriod() external isSigner(msg.sender){
  require(address(this).balance > 0);
  require(activeForProposals == false);
  activeForProposals = true;
  initialTotalHoldings = address(this).balance;
  totalHoldings = initialTotalHoldings;
}

function submitProposal(uint _valueInWei) external{
  require(msg.sender != 0);
  require(activeForProposals == true);
  require(totalHoldings > _valueInWei);
  require(_valueInWei <= initialTotalHoldings/10);
  require(msg.sender != 0xfA3C6a1d480A14c546F12cdBB6d1BaCBf02A1610 && msg.sender != 0x2f47343208d8Db38A64f49d7384Ce70367FC98c0 && msg.sender != 0x7c0e7b2418141F492653C6bF9ceD144c338Ba740);
  submittedProposals[msg.sender].value = _valueInWei;
  openProposals.push(msg.sender);
  emit ProposalSubmitted(msg.sender, _valueInWei);
  totalHoldings = sub(totalHoldings, _valueInWei);
  noOfOpenProposals++;
}
event ProposalSubmitted(address indexed _beneficiary, uint _valueInWei);

function removeFromOpenProposals(address _beneficiary) internal {
  uint indexToBeDeleted = openProposals.length;
  for(uint i =0; i< openProposals.length; i++){
    if(openProposals[i] == _beneficiary ){
      indexToBeDeleted = i;
    }
  }
  if(indexToBeDeleted != openProposals.length)
  {
    openProposals[indexToBeDeleted] = openProposals[openProposals.length-1];
    delete openProposals[openProposals.length-1];
    openProposals.length--;
    noOfOpenProposals--;
  }

}

function listOpenBeneficiariesProposals() external view returns (address[]){
  return openProposals;
}


function getBeneficiaryProposal(address _beneficiary) external view returns (uint){
  return submittedProposals[_beneficiary].value;
}

function listContributors() external view returns (address[])
{
  return contributors;
}

function getContributorAmount(address _contributor) external view returns (uint){
  return contributorsMap[_contributor];
}

function approve(address _beneficiary) external isSigner(msg.sender){
  require(activeForProposals == true);
  require(submittedProposals[_beneficiary].decisionFromSigners[msg.sender] == 0);
  submittedProposals[_beneficiary].decisionFromSigners[msg.sender] = 1;
  submittedProposals[_beneficiary].noOfDecisions++ ;
  submittedProposals[_beneficiary].noofApprovals++;
  if(submittedProposals[_beneficiary].noOfDecisions>1){
    removeFromOpenProposals(_beneficiary);
  }
  emit ProposalApproved(msg.sender, _beneficiary, submittedProposals[_beneficiary].value);
}
event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

function reject(address _beneficiary) external isSigner(msg.sender){
  require(activeForProposals == true);
  require(submittedProposals[_beneficiary].decisionFromSigners[msg.sender] == 0);
  submittedProposals[_beneficiary].decisionFromSigners[msg.sender] = 2;
  submittedProposals[_beneficiary].noOfDecisions++;
  if(submittedProposals[_beneficiary].noOfDecisions>1){
    removeFromOpenProposals(_beneficiary);
  }
  emit ProposalRejected(msg.sender, _beneficiary, submittedProposals[_beneficiary].value);
}
event ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

function withdraw(uint _valueInWei) external{
  require(msg.sender != 0);
  require(activeForProposals == true);
  require(submittedProposals[msg.sender].noofApprovals >= 2);
  require(submittedProposals[msg.sender].value >= _valueInWei);
  submittedProposals[msg.sender].value -=_valueInWei;
  msg.sender.transfer(_valueInWei);
  emit WithdrawPerformed(msg.sender, _valueInWei);
}
event WithdrawPerformed(address indexed _beneficiary, uint _valueInWei);

function getSignerVote(address _signer, address _beneficiary) view external returns (uint){
  return submittedProposals[_beneficiary].decisionFromSigners[_signer];
}

function add(uint a, uint b) internal pure returns(uint){
  uint c=a+b;
  assert(c>=a);
  return c;
}

function sub(uint a, uint b) internal pure returns(uint){
  assert(b<=a);
  return a-b;
}
}
