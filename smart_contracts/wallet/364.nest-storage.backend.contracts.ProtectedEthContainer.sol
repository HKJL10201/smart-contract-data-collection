pragma solidity ^0.4.23;

contract ProtectedEthContainer {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner can preform this action");
        _;
    }

    function () payable public {}

    function transferAmount (address _recipient, uint256 amount) public onlyOwner {
        _recipient.transfer(amount);
    }

    function getBalance() public view returns ( uint256 ) {
        return address(this).balance;
    }
}