// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.4;

contract Queue {
    mapping(uint256 => uint256) queue;
    uint256 first = 1;
    uint256 last = 0;

    function enqueue(uint256 data) public {
        last += 1;
        queue[last] = data;
    }
    
    function top() public view returns (uint256) {
        require(last >= first);  // non-empty queue
        return queue[first];
    }

    function dequeue() public returns (uint256 data) {
        require(last >= first);  // non-empty queue

        data = queue[first];

        delete queue[first];
        first += 1;
    }
    
    function empty() public view returns (bool) {
        return last < first;
    }
}