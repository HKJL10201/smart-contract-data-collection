// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// prefix external allows function to be called from outside the contract
// prefix view means function is read-only

contract eTrustWallet { 
    // this smart contract allows anyone to send money into it
    address payable public owner; // the owner is the one who deploys the contract to the Blockchain. Only he is allowed to withdraw from this contract
    address payable public special_friend; // however the owner can set a special friend, who can then withdraw as much as the owner

    enum State {Null, Set} // this checks the state of the special friend if he/she has been set.. once set it cannot be changedd
    State public state; //automatically set to first state

    constructor(){
        owner = payable(msg.sender); // the constructor function runs only once.. at the time contract is deployed
    }

    /// The function cannot be called.. you are not special or it has already been called
    error InvalidState();

    modifier inState(State state_) { //modifier function checking the state of special friend and calling InvalidState() if needed
        if(state != state_){
            revert InvalidState();
        }
        _;
    }

    receive() external payable {} // this alows Ether to enter into contract without any restriction

    function withdraw(uint _amount) external{
        require(msg.sender == owner, "Only the owner can call this method");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance; //gets amount of Ether in contract
    }

    function setFriend(address payable _friend) inState(State.Null) external {
        require(msg.sender == owner, "Only the owner can call this method");
        state = State.Set;
        special_friend = _friend;
    }

    function friend_withdraw(uint _amount) external {
        require(msg.sender == special_friend, "only special friend can call this method");
        payable(msg.sender).transfer(_amount);

    }
}

//eventually this will be made into a decentralized app (dAPP) for betting and lotteries. 