pragma solidity ^0.4.24;

contract MultiSigWallet {

    address[] public signers;
    Proposal[] public proposals;
    mapping(address => bool) public canSign;
    uint public signersRequired;
    
    struct Proposal {
        address to;
        uint amount;
        mapping(address => bool) signed;
        bool finalize;
    }
    
    constructor (address[] initSigners, uint signersRequirementsMet) public {
        signers = initSigners;
        
        if (signersRequirementsMet == 0) {
            signersRequired = initSigners.length;
        } else {
            signersRequired = signersRequirementsMet;
        }
        
        for(uint i=0; i < initSigners.length; i++) {
            canSign[initSigners[i]] = true;
        }
    }
    
    function balance () public view returns(uint) {
        return address(this).balance;
    }
    
    modifier onlySigner(address sender) {
        require(canSign[sender]);
        _;
    }
    
    function submitProposal(address to, uint amount) public onlySigner(msg.sender) {
        proposals.push(Proposal({
            to: to,
            amount: amount,
            finalize: false
        }));
    }
    
    modifier existProposal(uint index) {
        require(index >= 0 && index < proposals.length);
        _;
    }
    
    function signProposal(uint index) public onlySigner(msg.sender) existProposal(index) {
        proposals[index].signed[msg.sender] = true;
    }
        
    modifier fullySigned(uint index) {
        require(signersRequirementsMet(index));
        _;
    }
    
    function signersRequirementsMet(uint index) public view existProposal(index) returns(bool) {
        uint signedCount = 0;
        for (uint i = 0; i < signers.length; i++) {
            if (proposals[index].signed[signers[i]]) {
                signedCount++;
            }
        }
        return signedCount >= signersRequired;
    }

    function finalizeProposal(uint index) public onlySigner(msg.sender) fullySigned(index) {
        require(address(this).balance >= proposals[index].amount);
        require(proposals[index].finalize == false);
        proposals[index].finalize = true;
        proposals[index].to.transfer(proposals[index].amount);
    }
    
    function () public payable {
    }
    
}
