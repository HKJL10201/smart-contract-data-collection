pragma solidity ^0.4.19;


contract Owner {
    address public owner;
    function Owner() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
}
