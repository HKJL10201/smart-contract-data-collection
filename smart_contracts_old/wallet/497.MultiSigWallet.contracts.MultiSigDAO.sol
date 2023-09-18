pragma solidity ^0.4.23;

contract MultiSigDAO{
    /*
   * This function should return the owner of this contract or whoever you
   * want to receive the Gyaan Tokens reward if it's coded correctly.
   */
    address public contract_owner;
    bool isContributionPeriod = true;
    mapping (address => uint) public proposal;
    mapping (address => uint) public contribution;
    mapping (address => uint) public votes;
    mapping (address => uint) public approval;
    mapping (address => uint) public rejection;
    address[] public beneficiary_list;
    uint public beneficiary_counter = 0;
    address[] public contribution_list; 
    address[3] public signers = [0xfa3c6a1d480a14c546f12cdbb6d1bacbf02a1610, 0x2f47343208d8db38a64f49d7384ce70367fc98c0, 0x7c0e7b2418141f492653c6bf9ced144c338ba740];
    mapping(address => mapping(address => uint)) public signs;
    address[] openBeneficiaries;
    uint public tempProposalBal = 0;
    uint public contributionPeriodBal = 0;


    constructor() public{
        contract_owner = msg.sender;
    } 

   /*
   * This event should be dispatched whenever the contract receives
   * any contribution.
   */
    event ReceivedContribution(address indexed _contributor, uint _valueInWei);
    //emit ReceivedContribution();

    function() public payable{
        require(isContributionPeriod == true);
        if(contribution[msg.sender]>0){
            contribution[msg.sender] += msg.value;
        }else{
            contribution[msg.sender] += msg.value;
            contribution_list.push(msg.sender);
        }
        emit ReceivedContribution(msg.sender, msg.value);
    }
   
    function owner() external view returns(address){
        return contract_owner;
    }



  /*
   * When this contract is initially created, it's in the state
   * "Accepting contributions". No proposals can be sent, no withdraw
   * and no vote can be made while in this state. After this function
   * is called, the contract state changes to "Active" in which it will
   * not accept contributions anymore and will accept all other functions
   * (submit proposal, vote, withdraw)
   */
    function endContributionPeriod() external{
        require(msg.sender == signers[0] || msg.sender == signers[1] || msg.sender == signers[2]);
        require(address(this).balance > 0);
        contributionPeriodBal = address(this).balance;
        isContributionPeriod = false;
    }

  /*
   * Sends a withdraw proposal to the contract. The beneficiary would
   * be "_beneficiary" and if approved, this address will be able to
   * withdraw "value" Ethers.
   *
   * This contract should be able to handle many proposals at once.
   * DOUBT : above line
   * CORNER CASE: What if proposal is submitted more than once?
   */
    function submitProposal(uint _valueInWei) external{
        require(isContributionPeriod == false);
        require((msg.sender != signers[0]) && (msg.sender != signers[1]) && (msg.sender != signers[2]));
        require(proposal[msg.sender] == 0);
        //require((contributionPeriodBal-tempProposalBal) >= ((contributionPeriodBal)/10));
        require((contributionPeriodBal-tempProposalBal) >= _valueInWei);
        require(_valueInWei <= (contributionPeriodBal)/10);
        proposal[msg.sender] = _valueInWei;
        beneficiary_list.push(msg.sender);
        tempProposalBal += _valueInWei; 
        emit ProposalSubmitted(msg.sender, proposal[msg.sender]);
    }
    event ProposalSubmitted(address indexed _beneficiary, uint _valueInWei);

  /*
   * Returns a list of beneficiaries for the open proposals. Open
   * proposal is the one in which the majority of voters have not
   * voted yet.
   */
    function listOpenBeneficiariesProposals() external view returns (address[]){
        require(isContributionPeriod == false);
        for(uint i=0; i<beneficiary_list.length; i++){
            if(votes[beneficiary_list[i]] <= 1){
                openBeneficiaries.push(beneficiary_list[i]);
            }
        }
        return openBeneficiaries;
    }

  /*
   * Returns the value requested by the given beneficiary in his proposal.
   */
    function getBeneficiaryProposal(address _beneficiary) external view returns (uint){
        require(isContributionPeriod == false);
        return proposal[_beneficiary];
    }

  /*
   * List the addresses of the contributors, which are people that sent
   * Ether to this contract.
   */
    function listContributors() external view returns (address[]){
        return contribution_list;
    }

  /*
   * Returns the amount sent by the given contributor in Wei.
   */
    function getContributorAmount(address _contributor) external view returns (uint){
        return contribution[_contributor];
    }

    function checkStatus(address _beneficiary) internal{
        if(votes[_beneficiary]==3){
            if(rejection[_beneficiary]>=2){
                tempProposalBal -= proposal[_beneficiary];

                proposal[_beneficiary]==0;
                signs[_beneficiary][signers[0]] = 0;
                signs[_beneficiary][signers[1]] = 0;
                signs[_beneficiary][signers[2]] = 0;

                votes[_beneficiary] = 0;
                approval[_beneficiary] = 0;
                rejection[_beneficiary] = 0;
            }
        }
    }

    function checkBal(address _beneficiary) internal{
        if(proposal[_beneficiary]==0){
            signs[_beneficiary][signers[0]] = 0;
            signs[_beneficiary][signers[1]] = 0;
            signs[_beneficiary][signers[2]] = 0;

            votes[_beneficiary] = 0;
            approval[_beneficiary] = 0;
            rejection[_beneficiary] = 0;
        }
    }
  /*
   * Approve the proposal for the given beneficiary
   */
    function approve(address _beneficiary) external{
        require(isContributionPeriod == false);
        require(msg.sender == signers[0] || msg.sender == signers[1] || msg.sender == signers[2]);
        require(proposal[_beneficiary] != 0);
        require(signs[_beneficiary][msg.sender]!=1);
        signs[_beneficiary][msg.sender] = 1; 
        votes[_beneficiary] += 1;
        approval[_beneficiary] += 1;
        checkStatus(_beneficiary);
        emit ProposalApproved(msg.sender, _beneficiary, proposal[_beneficiary]);
    }
    event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

  /*
   * Reject the proposal of the given beneficiary
   */
    function reject(address _beneficiary) external{
        require(isContributionPeriod == false);
        require(msg.sender == signers[0] || msg.sender == signers[1] || msg.sender == signers[2]);
        require(proposal[_beneficiary] != 0);
        require(signs[_beneficiary][msg.sender]!=1);
        signs[_beneficiary][msg.sender] = 1; 
        votes[_beneficiary] += 1;
        rejection[_beneficiary] += 1;
        checkStatus(_beneficiary);
        emit ProposalRejected(signers[0], _beneficiary, proposal[_beneficiary]);
    }
    event ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

  /*
   * Withdraw the specified value in Wei from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
   * should be sent.
   *
   */
    function withdraw(uint _valueInWei) external{
        require(isContributionPeriod == false);
        require(approval[msg.sender]>=2);
        require(_valueInWei<=proposal[msg.sender]);
        msg.sender.transfer(_valueInWei);
        proposal[msg.sender] -= _valueInWei;
        checkBal(msg.sender);
        emit WithdrawPerformed(msg.sender, _valueInWei);
    }
    event WithdrawPerformed(address indexed _beneficiary, uint _valueInWei);

}