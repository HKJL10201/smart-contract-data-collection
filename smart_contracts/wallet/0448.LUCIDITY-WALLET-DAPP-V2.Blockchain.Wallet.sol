//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Wallet{
    //DATA TYPES
    address payable public walletOwner;
    //STRUCT
    struct Transaction {
        uint id;
        string subject;
        uint amount;
        address sender;
        address receiver;
    }

    //state variable

    uint public historyCount;
    //ARRAY

    Transaction [] public history;
    
    //CONSTRUCTOR
    constructor () {
        walletOwner = payable(msg.sender);
        historyCount = 0;
    }
    //MODIFIER

    modifier ownerPrivillege( ){
        require( msg.sender == walletOwner, "Only the owner of this wallet can call this function!!!");
        _;
    }
    //EVENTS
       event Deposited(uint indexed amount, string message, address depositor);
       event Transfered( uint indexed amount, string message, address receiver);
    
    //FUNCTIONS
    
    function displayCA ( ) public view returns (address) {
        return address(this);
    }

    function deposit() public payable{
        
        history.push(Transaction (historyCount++, "Deposit", msg.value, msg.sender, address(this) ));
       
        //Notification
        emit Deposited (msg.value, "Deposited by ", msg.sender);
    }

    
    function transfer (address payable Individual, uint amount ) public ownerPrivillege {
        //ensure that wallet balance is > request

        require(address(this).balance >= amount, "Insufficent balance!!!");

        // to be excuted if balance is more than enough

        Individual.transfer(amount);

      history.push(Transaction (historyCount++, "Transfer", amount, address(this), Individual ));
        //Notification
        emit Transfered (amount, "You just transfered to", Individual);
    }
    //Display my balance
    function balance ( ) public view returns (uint){
        return address(this).balance;
    }

    // Display history of the walllet

    function getHistory ( ) public view returns (Transaction [] memory){
        return history;
    }

    // get single transaction

    function getTransaction (uint _id) public view returns (Transaction memory ){
        return history[_id - 1];
    }

    // fallback function

    receive () external payable {

    } 

    //destory contract on my command 

    function destroy ( ) public ownerPrivillege {
        selfdestruct(walletOwner);

    }
}