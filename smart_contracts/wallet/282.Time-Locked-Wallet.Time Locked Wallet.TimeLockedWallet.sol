// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "./ERC20.sol";

contract TimeLockedWallet is ERC20 {
    address public creator;
    address public owner;
    uint public creationDate;
    uint public unlockDate;

    event Received(address _from, uint _amount);
    event Withdrew(address _to, uint _amount);
    event WithdrewTokens(address _tokenContract, address _to, uint _amount);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function timeLockedWallet (address _creator, address _owner, uint _unlockDate) public {
        creator = _creator;
        owner = _owner;
        unlockDate = _unlockDate;
        creationDate = block.timestamp;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public payable{
        require(block.timestamp>=unlockDate);
        require(_amount < address(this).balance);
        owner.transfer(_amount);
        emit Withdrew(msg.sender, this.balance);
    }

    function info() public view returns(address, address, uint, uint, uint) {
        return (creator, owner, creationDate, unlockDate, this.balace);
        
    }

    function withdrawTokens(address _tokenContract) public {
        require(now>=unlockDate);
        ERC20 token = ERC20(_tokenContract);
        uint tokenBalance = token.balanceOf(this);
        token.transfer(owner, tokenBalance);
        emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
        
    }

}