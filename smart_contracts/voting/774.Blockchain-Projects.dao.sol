// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 <0.9.0;

contract Dao{
    struct Proposal{
        uint id;
        string  description;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool isExecuted;
    }

    mapping(address =>bool) private isInvestor;
    mapping(address =>uint ) private numOfShares;
    mapping(address =>mapping(uint=> bool)) public isVoted;
    // mapping(address =>mapping(address=>bool)) public withdrawlStatus;
    address[] public investorsList;
    mapping(uint =>Proposal) public proposals;
    
    uint public totalsShares;
    uint public availableFunds;
    uint public ContributionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public manager;

    constructor(uint _contributionTimeEnd,uint _voteTime, uint _quorum){
        require (_quorum>0 && _quorum<100, "Not valid Values");
        ContributionTimeEnd = block.timestamp+_contributionTimeEnd;
        voteTime =_voteTime;
        quorum = _quorum;
        manager = msg.sender;
    }
    modifier onlyInvestor(){
        require(isInvestor[msg.sender]==true,"You are not an investor");
        _;

    }
    modifier onlyManager(){
        require(manager == msg.sender,"You are not a manager");
        _;
    }
    function contribution() public payable{
        require(ContributionTimeEnd>=block.timestamp, "Contribution Time End");
        require(msg.value>0, "send more than 0 ether");
        isInvestor[msg.sender]=true;
        numOfShares[msg.sender]=numOfShares[msg.sender]+msg.value;
        totalsShares+=msg.value;
        availableFunds+=msg.value;
        investorsList.push(msg.sender);
    }

    function redeemShare(uint amount) public onlyInvestor(){
        require(numOfShares[msg.sender]>= amount,"You don't have enough shares");
        require(availableFunds>=amount,"not enough funds");
        numOfShares[msg.sender]-=amount;
        if(numOfShares[msg.sender]==0 ){
            isInvestor[msg.sender]=false;

        }
        availableFunds -=amount;
        payable(msg.sender).transfer(amount);
    }
    function transferShare(uint amount,address to) public onlyInvestor(){
        require(availableFunds>= amount,"Not enough funds");
        require(numOfShares[msg.sender]>=amount, "You don't have enough shares");
        numOfShares[msg.sender]-=amount;
        if(numOfShares[msg.sender]==0){
            isInvestor[msg.sender]=false;
        }
        numOfShares[to]+=amount;
        isInvestor[to]=true;
        investorsList.push(to);
    }
    function createProposal(string calldata description,uint amount,address payable recipient) public{
        require(availableFunds>=amount,"Not enough funds");
        proposals[nextProposalId]=Proposal(nextProposalId,description,amount,recipient,0,block.timestamp+voteTime, false);
        nextProposalId++;

    }
    function voteProposal(uint proposalid) public onlyInvestor(){
        Proposal storage proposal = proposals[proposalid];
        require (isVoted[msg.sender][proposalid]== false,"You have already voted for this program");
        require(proposal.end>= block.timestamp,"voting time End");
        require(proposal.isExecuted== false,"It os already executed");
        isVoted[msg.sender][proposalid]= true;
        proposal.votes+= numOfShares[msg.sender];
    }
    function executeProposal(uint proposalid) public onlyManager(){
        Proposal storage proposal=proposals[proposalid];
        require(((proposal.votes*100)/totalsShares)>=quorum,"Majority does not support");
        proposal.isExecuted= true;
        _transfer(proposal.amount,proposal.recipient);

    }
    function _transfer(uint amount, address payable recipient) public{
        recipient.transfer(amount);
    }
    function ProposalList() public view returns(Proposal[] memory){
        Proposal[] memory arr = new Proposal[](nextProposalId-1);
        for(uint i=0; i<nextProposalId; i++){
            arr[i]=proposals[i];
        }
        return arr;
    }

}