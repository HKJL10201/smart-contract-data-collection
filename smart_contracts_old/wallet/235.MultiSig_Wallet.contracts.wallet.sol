pragma solidity ^0.8.9;

import '../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './WalletFactory.sol';

contract Wallet is ReentrancyGuard{
    
    using SafeMath for uint256;

    uint256 limit;
    address walletInstance;

    address[] public owners;

    struct Transfer {
        uint256 id;
        uint256 amount;
        address sender;
        address payable reciever;
        uint256 approvals;
        bool hasBeenSent;
        bytes10 ticker;
    }
   
    struct Tokens{
        bytes10 ticker;
        address tokenAdd;
    }

    Transfer[] transferRequests;

    mapping(bytes10 => Tokens) public availableTokens;
    mapping(address => mapping(uint256 => bool))approvals;
    mapping(address => mapping(bytes10 => uint256))balance;

    event ApprovalRecieved( uint256 _id, uint256 _approvals, address _approver );
    event TransferRequestCreated( uint256 _id, uint256 _amount, address _initiator, address _receiver );
    event TransferApproved( uint256 _id );
    event TransferMade( uint256 _id, uint256 _amount, address _sender, address _reciever, bool _hasBeenSent, bytes10 _ticker);
    event ethDeposited( uint256 _amount, address _reciever );
    event ethWithdrawn( uint256 _amount, address _reciever );
    event tokenDeposited( uint256 _amount, address _reciever, bytes10 _ticker );
    event tokenWithdrawn( uint256 _amount, address _reciever, bytes10 _ticker );
    event transferCancelled( bytes10 _ticker, uint _id, address _sender, address _receiver, uint amount );


    modifier onlyOwners(){
        bool owner = false;
        for(uint256 i = 0; i < owners.length; i++){
            if(owners[i]== msg.sender){
                owner = true;
            }
        }
        require (owner = true);
        _;
    }

    constructor(address[] memory _owners){
        owners = _owners;
        limit = calculateLimit(owners.length);
        // tokenList.push("ETH");
    }




    
    /******** Deposit/Withdraw Functions **********/

    function depositETH()public payable onlyOwners{
        require(msg.value > 0, "you must enter an amount greater than 0");
        balance[msg.sender][bytes10("ETH")] = balance[msg.sender][bytes10("ETH")].add(msg.value);

        emit ethDeposited(msg.value, msg.sender);
    }

    function withdrawETH(uint256 _amount) external payable onlyOwners {
        require(_amount < balance[msg.sender][bytes10("ETH")]);
        balance[msg.sender][bytes10("ETH")] = balance[msg.sender][bytes10("ETH")].sub(_amount);
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "withdraw failed");

        emit ethWithdrawn(_amount, msg.sender);
    }

    function depositToken(bytes10 _ticker, uint256 _amount) external payable onlyOwners{
        require(_amount > 0, "you must enter an amount greater than 0");
        require(availableTokens[_ticker].tokenAdd != address(0), "Not a valid token");

        IERC20(availableTokens[_ticker].tokenAdd).transferFrom(msg.sender, address(this), _amount);
        balance[msg.sender][_ticker] = balance[msg.sender][_ticker].add(_amount);

        emit tokenDeposited(_amount, msg.sender, _ticker);
        
    }

    function withdrawToken(bytes10 _ticker, uint256 _amount) external onlyOwners{
        require(_amount <= balance[msg.sender][_ticker], "cannot withdraw more than your balance");
        balance[msg.sender][_ticker] = balance[msg.sender][_ticker].sub(_amount);
        IERC20(availableTokens[_ticker].tokenAdd).transfer( msg.sender, _amount );

    }





    /********* Transfer Functions *********/

    function createTransfer(uint256 _amount, address payable _reciever, bytes10 _ticker) public onlyOwners{

        Transfer memory t;

        t.id = transferRequests.length;
        t.amount = _amount;
        t.sender = msg.sender;
        t.reciever = _reciever;
        t.approvals = 0;
        t.hasBeenSent = false;
        t.ticker = _ticker;

        transferRequests.push(t);

        emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _reciever);
    }

    function approve(bytes10 _ticker, uint256 _id) public onlyOwners {
       
        require (approvals[msg.sender][_id] == false, "You are not able to approve twice");
        require (transferRequests[_id].hasBeenSent == false, "You can't approve a sent transaction");

        emit ApprovalRecieved(_id, transferRequests[_id].approvals, msg.sender);

        approvals[msg.sender][_id] == true;
        transferRequests[_id].approvals++;
        //condition
        if(transferRequests[_id].approvals >= limit){
            transferRequests[_id].hasBeenSent = true;
            transferFunds(_ticker, _id);
            // transferRequests[_id].reciever.transfer(transferRequests[_id].amount);
            emit TransferApproved(_id);
        }
    }
    
    
    // Any gas specific code should be avoided because gas costs can and will change.
    //  call() is more gas efficient
    function transferFunds(bytes10 _ticker, uint _id) private nonReentrant{ 
        
        address reciever = transferRequests[_id].reciever;
        uint amount = transferRequests[_id].amount;
        
        if(_ticker == "ETH"){
            (bool success, ) = reciever.call{ value: amount }("");
            require(success, "Transfer Failed");
            
        }else{
            IERC20(availableTokens[_ticker].tokenAdd).transfer(reciever, amount);
            
        }
        emit TransferMade( _id, amount, msg.sender, reciever, true, _ticker);
        //update balance
        balance[reciever][_ticker] = balance[reciever][_ticker].add(amount);
        
        //update transferRequest array 
        transferRequests[_id] = transferRequests[transferRequests.length -1];
        transferRequests.pop();
    }

    function cancelTransfer( bytes10 _ticker, uint256 _id) public onlyOwners{
        uint256 index = 0;
        bool found;
        for(uint i = 0; i < transferRequests.length; i++){
            if(transferRequests[i].id == _id){ 
                found = true;
                break; 
            }
            index++;
        }
        if(!found) revert("The transfer id has not been found");

        balance[msg.sender][_ticker] += transferRequests[index].amount;

        emit transferCancelled(
            _ticker, 
            _id, 
            msg.sender, 
            transferRequests[index].reciever, 
            transferRequests[index].amount 
            );
        
        transferRequests[index] = transferRequests[transferRequests.length - 1];
        transferRequests.pop();
    }









    /******** Owner Array setter functions **********/

    
    function addOwner(address _newOwner) public onlyOwners{
      
        for(uint i=0; i < owners.length; i++){
            if(owners[i] == _newOwner){
                revert("user is already an owner");
            }else{
                owners.push(_newOwner);
            }
        }
        
        calculateLimit(owners.length);
    }
    
    function removeOwner(address _ownerToRemove) public onlyOwners{
        uint userIndex;
        
        for(uint i = 0; i <= owners.length; i++){
            if(owners[i] == _ownerToRemove){
                userIndex == i;
                require(owners[i] == _ownerToRemove, "the owner doesnt exist");
            }
        }
        
        owners[userIndex] = owners[owners.length - 1];
        owners.pop();
        calculateLimit(owners.length);

        // WalletFactory factory = WalletFactory(walletInstance);
    }

    

    
    


    /********* Helper Functions *********/

    function getBalance(bytes10 _ticker)public view returns(uint){
        return balance[msg.sender][_ticker];
    }
    
    //75% of wallet owners must approve
    function calculateLimit(uint numOfAdd) public returns(uint){
        uint _limit = numOfAdd *75 / 100;
        limit = _limit;
        return limit;
    }


    function getLimit() public view returns(uint){
        return limit;
    }


    function getTransferRequests() public view returns(Transfer[] memory){
        return transferRequests;
    }

}