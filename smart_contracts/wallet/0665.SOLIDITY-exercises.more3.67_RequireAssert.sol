//SPDX-Licence-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract ModifierTest {

    bool public paused;
    uint public myNumber;

    function startStop(bool _start) external {
        paused = _start;
    } 

    function decNumber() external {
        require(!paused, "paused");
        myNumber -=10;
    }

    function addNumber() external {
        require(!paused, "paused");
        myNumber +=30;
    }
    uint x = 6;
    function checkNumber(uint a) external {
        require(a > 5, "no you cant do that");
        x = x+a;
        assert(x > 6);
    }
}