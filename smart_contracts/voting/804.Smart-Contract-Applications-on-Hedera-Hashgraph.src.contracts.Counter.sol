// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Counter {
    uint public count;
    
    event CountIncrement(address indexed _from, uint count);

    function increment() external {
        count += 1;
        emit CountIncrement(msg.sender, count);
    }
}
