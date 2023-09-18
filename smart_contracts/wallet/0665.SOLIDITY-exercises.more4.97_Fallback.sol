//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Apple {

    event LogSomething(string funcName, uint money, address sender, bytes somedata);

    fallback() external payable {
        emit LogSomething("fallback", msg.value, msg.sender, msg.data);
    }

    receive() external payable {
        emit LogSomething("receive", msg.value, msg.sender, "");
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    /* fallback function is used to let our contract to receive ether if the called function does not exist.

    We must declare fallback and receive functions as "payable" so that they can receive ether.
    
    Declaring fallback function is cruel because any wrong call will cost caller ETH(msg.value).

    Declaring receive function is more humane, because if "receive" function is triggered,
    the call will revert, msg.value will be returned.

    msg.data = a special variable that contains function selector + arguments
    if selector and/or arguments are wrong or missing, then fallback will be triggered.
    
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

    https://blog.soliditylang.org/2020/03/26/fallback-receive-split/
    https://sergiomartinrubio.com/articles/solidity-fallback-and-receive-functions/

     */
    


}