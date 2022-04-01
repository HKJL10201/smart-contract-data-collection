//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Main {
    /* fallback function is used to let our contract to receive ether if the function called does not exist.
    And alternative to fallback() is receive() function. But receive() 
    We must declare fallback and receive functions as "payable" so that they can receive ether.
    
    Declaring fallback function is cruel because any wrong call will cost caller ETH.

    Declaring receive function is more humane, because if value not defined the receive function will not charge anything 
    and wrong calls will not cost eth.
    
     is msg.data empty?
            /           \
           Yes          No
            |             \
        is receive()        fallback()
        defined?             
          /    \
        Yes     No          
        /        \
 receive()      fallback()

     */
    
    //THIS FLOORPLAN BELOW SHOULD EXISTS IN ALL PROJECTS:
    event LogSomething(string funcName, uint idiotMoney, address idiotAccount, bytes idiotData);

    fallback() external payable {
        emit LogSomething("fallback", msg.value, msg.sender, msg.data);
    }

    receive() external payable {
        emit LogSomething("receive", msg.value, msg.sender, ""); //Here, it cannot include msg.data
        //But i cannot leave it empty either. So I must put an empty string
    }
}