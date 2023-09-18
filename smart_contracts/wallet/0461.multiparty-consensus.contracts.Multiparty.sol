// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/** 
 * @title Multiparty
 * @dev Implements multiparty wallet which includes admin privileges and proposal approval
 */

contract Multiparty {
    //define state data for admin
    address private admin;

    //define mapping for wallet owners
    mapping(address => bool) private walletOwner;

    //define state data for wallet count
    uint public walletsCount = 0;

    //define struct for proposal
    struct proposal {
        address owner;
        uint256 numApprovals;
        uint threshold;
    }

     //define a dynamically-sized array to hold proposal addresses
    address[] proposalArray;

    //define mapping for proposal
    mapping(address => proposal) public proposals;

    //define multi-dimensional mapping for proposal wallet approvers
    mapping(address => mapping(address => bool)) hasApprovedProposal;



    //modifier to check if function caller is the admin
    modifier isAdmin (){
        require(msg.sender == admin, "Function caller address is not an admin");
        _;
    }

    //modifier to check if address is a wallet owner
    modifier isWalletOwner (){
        require(walletOwner[msg.sender]  == true, "Function caller address is not a valid wallet owner");
        _;
    }

    //modifier to check if wallet is address(0)
    modifier notAddressZero (address _wallet){
        require(_wallet != address(0), "Unable to add address(0) as a wallet address");
        _;
    }

    //modifier to confirm that address is not the proposal owner
    modifier isNotProposalOwner (address _proposalAddress){
        require(proposals[_proposalAddress].owner != msg.sender, "Proposal owner is not allowed to approve own proposal");
        _;
    }

    //modifier to confirm that address is the proposal owner
    modifier isProposalOwner (address _proposalAddress){
        require(proposals[_proposalAddress].owner == msg.sender, "Function caller is not owner of proposal");
        _;
    }

    //modifier to ensure that the proposal has reached approval threshold
    modifier hasReachedThreshold (address _proposalAddress) {
        uint currentPercentage = (proposals[_proposalAddress].numApprovals * 100 ) / walletsCount;
        require (currentPercentage >= proposals[_proposalAddress].threshold, "Aprroval threshold not yet enough to execute proposal");
        _;
    }

    //modifier to confirm that proposal does not already exist
    modifier proposalDoesNotExist (address _proposalAddress){
        require(proposals[_proposalAddress].owner == address(0), "Proposal already exists");
        _;
    }

    //modifier to ensure that address has not apporved proposal
    modifier hasNotApprovedProposal (address _proposalAddress){
        require(hasApprovedProposal[_proposalAddress][msg.sender] == false, "Wallet has already approved proposal");
        _;
    }


    //define event for successful wallet owner addition
    event walletOwnerAdded(address _walletAddress);

    //define event for successful wallet owner removal
    event walletOwnerRemoved(address _walletAddress);

    //define event for successful proposal submission
    event proposalSubmitted(address _walletAddress, address _proposalAddress);

     //define event for successful proposal approval
    event proposalApproved(address _walletAddress, address _proposalAddress);

     //define event for successful proposal execution
    event proposalExecuted(address _walletAddress, address _proposalAddress);

    //define contract constructor and grant admin role to the contract deployer
    constructor (){
        //grant admin role to the contract deployer
       admin = msg.sender;
       //make admin a valid wallet owner
       walletOwner[msg.sender] = true;
       walletsCount++;
    }

    /** 
    * @param _proposalAddress Address value of proposal
    * @param _threshold Sets threshold value for proposal
    * @dev Define function to set approval threshold required to execute proposal
    */
    function setThreshold (address _proposalAddress, uint _threshold) public isAdmin returns (bool){
        require(_threshold <= 100, "Threshold value can't be more than 100");
        proposals[_proposalAddress].threshold = _threshold;
        return true;
    }

    
    /** 
    * @param wallet Wallet address to add
    * @dev Function to add address to wallet owners
    */
    function addWalletOwner (address wallet) public isAdmin notAddressZero(wallet) returns (bool) {
        require(walletOwner[wallet] == false, "Address already a wallet owner"); //ensure wallet had not been added
       walletOwner[wallet] = true;
       walletsCount++;
       emit walletOwnerAdded(wallet);
       return true;
    }


    /** 
    * @param wallets Wallet addresses to add
    * @dev Function for batch addition of addresses to wallet owners
    */
    function addWalletOwners (address[] memory wallets) public isAdmin {
        require(wallets.length <= 30, "Amount of wallets exceeds allowable maximum");
        for (uint i=0; i<wallets.length; i++) {
             require(walletOwner[wallets[i]] == false, "Address already a wallet owner");
            walletOwner[wallets[i]] = true;
            walletsCount++;
        }
    }

    /** 
    * @param wallet Wallet address to remove
    * @dev Function to remove address from wallet owners
    */
    function removeWalletOwner (address wallet) public isAdmin notAddressZero(wallet) returns (bool){
        require(walletOwner[wallet] == true, "Address not a wallet owner"); //ensure wallet had not been added
       walletOwner[wallet] = false;
       walletsCount--;
       emit walletOwnerAdded(wallet);
       return true;
    }

    
     /** 
    * @param wallets Wallet address to remove
    * @dev Function for batch removal of addresses from wallet owners
    */
    function removeWalletOwners (address[] memory wallets) public isAdmin {
        require(wallets.length <= 30, "Amount of wallets exceeds allowable maximum");
        for (uint i=0; i<wallets.length; i++) {
            require(walletOwner[wallets[i]] == true, "Address not a wallet owner"); //ensure address is an existing wallet owner
            walletOwner[wallets[i]] = false; 
            walletsCount--;
        }
    }

    
     /** 
    * @param _proposalAddress Address of proposal to submit
    * @dev Function for submission of proposals by valid wallet owners
    */
    function submitProposal (address _proposalAddress) public isWalletOwner proposalDoesNotExist(_proposalAddress) returns (bool) {
        proposals[_proposalAddress] = proposal({owner: msg.sender, numApprovals: 0, threshold: 60});
       proposalArray.push(_proposalAddress);
       emit proposalSubmitted(msg.sender, _proposalAddress);
       return true;
    }

    
    /** 
    * @param _proposalAddress Address of proposal to approve
    * @dev Function for proposal approval by valid wallet owners
    */
    function approveProposal (address _proposalAddress) public isWalletOwner isNotProposalOwner(_proposalAddress) hasNotApprovedProposal(_proposalAddress) returns (bool){
        hasApprovedProposal[_proposalAddress][msg.sender] = true;
        proposals[_proposalAddress].numApprovals += 1;
        emit proposalApproved(msg.sender, _proposalAddress);
        return true;
    }

    
    /** 
    * @param _proposalAddress Address of proposal to approve
    * @dev Function to execute proposal by only the proposal owner
    */
    function executeProposal (address _proposalAddress) public isWalletOwner isProposalOwner(_proposalAddress) hasReachedThreshold(_proposalAddress) returns (bool){
        hasApprovedProposal[_proposalAddress][msg.sender] = true;
        proposals[_proposalAddress].numApprovals += 1;
        emit proposalExecuted(msg.sender, _proposalAddress);
        return true;
    }
}