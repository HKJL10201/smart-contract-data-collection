pragma solidity ^0.6.4;

contract Ownable {
    address payable _owner;

    //assigns owner to person deploying contract
    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(), "You're not the Owner!!");
        _;
    }

    //verifies if address is the owner
    function isOwner() public view returns(bool) {
        return (msg.sender == _owner);
    }
}
