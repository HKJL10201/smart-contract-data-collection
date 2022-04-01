//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma abicoder v2;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MultiSigWallet {

////////////////////////////Global Variables & Mappings///////////////////////////

    address MultiSigInstance;
    address mainOwner;
    uint public limit;
    uint256 public depositId = 0;
    uint256 public withdrawalId = 0;
    uint256 public transferId = 0;
    Transfer[] transferRequests;
    address[] owners;
    string[] public tokenList;

    mapping(address => mapping(uint => bool)) public approvals;
    mapping(address => mapping(string => uint)) public balances;
    mapping(string => Token) public tokenMapping;
 

////////////////////////////Constructor///////////////////////////
//used to set the main owner, the approval limit and sets eth as default token
//on the deployment of the contract

    constructor(address _owner) {
        mainOwner = _owner;
        owners.push(mainOwner);
        limit = owners.length - 1;
        tokenList.push("ETH");
    }
    

////////////////////////////Data Strructures (Structs)///////////////////////////
//here we have a transfer struct and token struct used to create instances of each

    struct Transfer{
        string ticker;
        uint amount;
        address sender;
        address payable receiver;
        uint approvals;
        uint id;
        uint timeOfCreation;
    }

    struct Token {
        string ticker;
        address tokenAddress;
    }
    
    
////////////////////////////Modifiers///////////////////////////

    modifier onlyOwners(){
        bool owner = false;
        for(uint i=0; i<owners.length;i++){
            if(owners[i] == msg.sender){
                owner = true;
            }
        }
        require(owner == true);
        _;
    }

    modifier tokenExists(string memory ticker) {
        
        require(tokenMapping[ticker].tokenAddress != address(0), "Token does not exist");
         _;
    }
    

////////////////////////////Events///////////////////////////

    event fundsDeposited(string ticker, address from, uint256 id, uint amount, uint256 timeStamp);
    event fundsWithdrawed(string ticker, address from, uint256 id, uint amount, uint256 timeStamp);
    event TransferRequestCreated(string ticker, uint id, uint _amount, address _initiator, address _receiver);
    event ApprovalReceived(string ticker, uint id, uint _approvals, address _approver);
    event TransferApproved(string ticker, uint id);
    event transferRequestApproved(string ticker, uint id, address sender, address receiver, uint amount, uint timeStamp);
    event transferRequestCancelled(string ticker, uint id, address sender, address receiver, uint amount, uint timeStamp);

   
    
    function addToken(string memory ticker, address tokenAddress) external onlyOwners {

        for(uint i = 0; i < tokenList.length; i++) {
            if(keccak256(bytes(tokenList[i])) == keccak256(bytes(ticker))) {
                revert("Token already added");
            }
        }
        require(keccak256(bytes(ERC20(tokenAddress).symbol())) == keccak256(bytes(ticker)));
        
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        //add the new token to the token list
        tokenList.push(ticker);
    }
    
////////////////////////////Functions for Dynamically Adding and Removing Wallet Owners///////////////////////////
    //add user function. require owner is not already in the wallet array
    function addUsers(address _owners, address _address, address walletAddress) public onlyOwners
    {
        for (uint user = 0; user < owners.length; user++)
        {
            require(owners[user] != _owners, "Already registered");
        }
        require(owners.length <= 5);
        owners.push(_owners);
        
        //from the current array calculate the value of minimum consensus
        limit = owners.length - 1;
        
         MultiSigInstance = _address;
        callAddOwner(_owners, walletAddress );
    }
    
    //remove user require the address we pass in is the address were removing
    function removeUser(address _user, address _address, address walletAddress) public onlyOwners
    {
        uint user_index;
        for(uint user = 0; user < owners.length; user++)
        {
            if (owners[user] == _user)
            {   
                user_index = user;
                require(owners[user] == _user);
            }
        }
        
        owners[user_index] = owners[owners.length - 1];
        owners.pop();
        limit= owners.length - 1;
        
         MultiSigInstance = _address;
        callRemoveOwner(_user, walletAddress );
    }

//this function is used to set the address of the current logged in wallet instance that the user is using

//this function updates the users list of available wallets. This function is used from the multisig fsctory contract   
    function callAddOwner(address owner, address wallet) private {
        MultiSigFactory factory = MultiSigFactory(MultiSigInstance);
        factory.addOwner(owner, wallet);
    }

//this function updates the users list of available wallets. This function is used from the multisig fsctory contract   
    function callRemoveOwner(address owner, address wallet) private {

        MultiSigFactory factory = MultiSigFactory(MultiSigInstance);
        factory.removeOwner(owner, wallet);
    }
    
    
    //gets wallet users
    function getUsers() public view returns(address[] memory)
    {
        return owners;
    }
    
   
    
////////////////////////////Functions for deopositing and withdrawing assets to and from the wallet///////////////////////////
    //deposit function. require deposit amount i sgreater than 0 and withdrawalRequests//the wallet oweners array is greater than 1
    function deposit() public onlyOwners payable {
        
        require(msg.value >= 0);
    
        balances[msg.sender]["ETH"] += msg.value;
        emit fundsDeposited("ETH", msg.sender, depositId, msg.value, block.timestamp);
        depositId++;
    }

    function depositERC20Token(uint amount, string memory ticker) external onlyOwners tokenExists(ticker) {

        require(tokenMapping[ticker].tokenAddress != address(0));
    
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender][ticker] += amount;  
        
        //emit deposited(msg.sender, address(this), amount, ticker);
        emit fundsDeposited(ticker, msg.sender, depositId, amount, block.timestamp);
        depositId++;
    }

    //after transfer is called our balance i < transaction amount thus we cannot withfraw
    //update amount after transfer function.
    function withdraw(string memory ticker, uint _amount) public onlyOwners {
    
        require(balances[msg.sender][ticker] >= _amount);
        balances[msg.sender]["ticker"] -= _amount;

        if(keccak256(bytes(ticker)) == keccak256(bytes("ETH")))  {
            payable(msg.sender).transfer(_amount);
        }
        else {
            require(tokenMapping[ticker].tokenAddress != address(0));
            IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, _amount);
        }
        
        emit fundsWithdrawed(ticker, msg.sender, withdrawalId, _amount, block.timestamp);
        withdrawalId++;
        
    }

    //withdrawal function
    // function withdrawERC20Token(uint amount, string memory ticker) external tokenExists(ticker) onlyOwners {
    //     require(tokenMapping[ticker].tokenAddress != address(0));
    //     require(balances[msg.sender][ticker] >= amount);

    //     balances[msg.sender][ticker] -= amount;
    //     IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    //     emit fundsWithdrawed(ticker, msg.sender, withdrawalId, amount, block.timestamp);
    //     withdrawalId++;

    // }

        
////////////////////////////Functions for approving, cancelling and executing transfers within the wallet///////////////////////////

    //Create an instance of the Transfer struct and add it to the transferRequests array
    function createTransfer(string memory _ticker, uint _amount, address payable _receiver) public onlyOwners {

        require(balances[msg.sender][_ticker] >= _amount, "insufficient balance to create a transfer reauest");
    
        for (uint i = 0; i < owners.length; i++) {
            require(owners[i] != _receiver, "only the wallet owners can make transfer reuqests");
        }
        
        balances[msg.sender][_ticker] -= _amount;
        transferRequests.push(Transfer(_ticker, _amount, msg.sender, _receiver, 0, transferId, block.timestamp));
        emit TransferRequestCreated(_ticker, transferId, _amount, msg.sender, _receiver);
        transferId++;
        
    }


    function cancelTransfer(string memory ticker, uint _id) public {
        // require(transferRequests[_id].sender == msg.sender, "only the user who created the transfer can cancel");

        uint counter = 0;
        bool hasBeenFound = false;
        for(uint i = 0; i < transferRequests.length; i++) {
           if(transferRequests[i].id == _id) {
               hasBeenFound = true;
               break;
           }
           counter++;
        }
        if(hasBeenFound == false) revert("Trnasfer ID not found cancellation");


        balances[msg.sender][ticker] += transferRequests[counter].amount;
        emit transferRequestCancelled(ticker, transferRequests[counter].id, msg.sender, transferRequests[counter].receiver, transferRequests[counter].amount, block.timestamp);

        transferRequests[counter] = transferRequests[transferRequests.length - 1];
        transferRequests.pop();


    }
    
    
    
    
    function Transferapprove(string memory ticker, uint _id) public onlyOwners {

        uint counter = 0;
        bool hasBeenFound = false;
        for(uint i = 0; i < transferRequests.length; i++) {
           if(transferRequests[i].id == _id) {
               hasBeenFound = true;
               break;
           }
           counter++;
        }
        if(hasBeenFound == false) revert("Transfer ID not found for approval");

        require(msg.sender != transferRequests[counter].sender);
        require(approvals[msg.sender][_id] == false, "transaction alrady approved");

        approvals[msg.sender][counter] = true;
        transferRequests[counter].approvals++;
        
        emit ApprovalReceived(ticker, counter, transferRequests[counter].approvals, msg.sender);

        if(transferRequests[counter].approvals == limit) {

            TransferFunds(ticker, counter);
        }

    }    

     //now we need to create a function to actually transfer the funds after the
    //transfer has been recieved
    function TransferFunds(string memory _ticker, uint _id) private {

        if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH")))  {
            transferRequests[_id].receiver.transfer(transferRequests[_id].amount);
        }
        else {
            IERC20(tokenMapping[_ticker].tokenAddress).transfer(transferRequests[_id].receiver, transferRequests[_id].amount);
        }
        
        balances[transferRequests[_id].receiver][_ticker] += transferRequests[_id].amount;
       
        emit transferRequestApproved(_ticker, transferRequests[_id].id, msg.sender, transferRequests[_id].receiver, transferRequests[_id].amount, block.timestamp);

        transferRequests[_id] = transferRequests[transferRequests.length - 1];
        transferRequests.pop();
        
    }
    
////////////////////////////Helper functions and blockhain reading functions///////////////////////////

    
    //Should return all transfer requests
    function getTransferRequests() public view returns (Transfer[] memory){
       
        return transferRequests;
    }

    
    //next we want to make a get balance function
    function getAccountBalance(string memory ticker) public view returns(uint)
    {
        return balances[msg.sender][ticker];
    }
    
    function getTokenList() public view returns (string[] memory) {
        
        return tokenList;
    }
    
    
}






contract MultiSigFactory {
    
     struct UserWallets{

        address walletAddress;
        uint walletID;
    }

    uint id = 0;
    UserWallets[] public wallets;
    MultiSigWallet[] public multisigInstances;

    mapping(address => UserWallets[]) userWallet;
    event multisigInstanceCreated(uint date, address walletOwner, address multiSigAddress);
   
    function createMultiSig() public {

        MultiSigWallet newWalletInstance = new MultiSigWallet(msg.sender);
        multisigInstances.push(newWalletInstance);
        
        UserWallets[] storage newWallet = userWallet[msg.sender];
        newWallet.push(UserWallets(address(newWalletInstance), id));
        
        emit multisigInstanceCreated(block.timestamp, msg.sender, address(newWalletInstance));
        id++;
    }
    
    function getUserWallets() public view returns (UserWallets[] memory wals) {
        return userWallet[msg.sender];
    }
    
    function addOwner(address account, address walletAddres) public {
        
        UserWallets[] storage newWallet = userWallet[account];
        newWallet.push(UserWallets(walletAddres, id));
      
    }
    
    function getWalletID(address walletAddres) public view returns (uint) {
        
        uint walletId;
        UserWallets[] memory newWallet = userWallet[msg.sender];
        for (uint i = 0; i < newWallet.length; i ++) {
            if (newWallet[i].walletAddress == walletAddres){
                walletId = newWallet[i].walletID;
            }
        }  
        return walletId;
    }

    function removeOwner(address account, address walletAddres) public {
        
        UserWallets[] storage newWallet = userWallet[account];
       
        uint walletIndex;
        bool hasBeenFound = false;
        for(uint i = 0; i < newWallet.length; i++)
        {
            if (newWallet[i].walletAddress == walletAddres)
            {   
                walletIndex = i;
                hasBeenFound = true;
            }
        }
        require(hasBeenFound);

        newWallet[walletIndex] = newWallet[newWallet.length - 1];
        newWallet.pop();
    }
     
}   









