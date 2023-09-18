// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Voting {

    address public owner;
    mapping (address => bool) public voted;
    
    struct Item {
        string name;
        uint256 votes;
    }
    
    Item[] public voteItems;
    bool public closed;
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    function initialize(address _owner) external {
        require(owner == address(0x0), "The contract is already initialized");
        owner = _owner;
    }
    
    event voteChanged(uint256 idx);
    event pollClosed();
    
    function vote(uint256 idx) external {
        require(!closed, "The poll is closed!");
        require(!voted[msg.sender], "You have already voted!");
        require(idx < voteItems.length, "Invalid index!");
        
        voted[msg.sender] = true;
        voteItems[idx].votes++;
        emit voteChanged(idx);
    }
    
    function close() isOwner external {
        require(!closed, "The poll is already closed!");
        closed = true;
        emit pollClosed();
    }
    
    function addItem(string memory name) isOwner external {
        voteItems.push(Item(name, 0));
        emit voteChanged(voteItems.length - 1);
    }
    
    function itemCnt() external view returns (uint256) {
        return voteItems.length;
    }
    
}
