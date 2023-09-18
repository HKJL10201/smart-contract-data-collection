pragma solidity ^0.8.0;

contract Wallet {
    address public owner;
    
    constructor(address _owner) {
        owner = _owner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function invoke(address _target, uint _value, bytes calldata _data) external onlyOwner {
        (bool success,) = _target.call{value: _value}(_data);
        require(success, "Transaction failed.");
    }
    receive() external payable {
    }
}