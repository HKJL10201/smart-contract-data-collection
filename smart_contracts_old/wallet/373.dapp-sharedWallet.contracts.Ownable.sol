pragma solidity 0.8.4;


contract Ownable {
    address  public  owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'You are not the owner');
        _;
    }
    
    function isOwner() public view returns(bool) {
        return owner == msg.sender;
    }
}