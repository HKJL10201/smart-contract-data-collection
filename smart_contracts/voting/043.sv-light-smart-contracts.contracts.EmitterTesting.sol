pragma solidity ^0.4.24;

contract EmitterTesting {
    event Log(string message);

    function log(string m) public {
        emit Log(m);
    }
}
