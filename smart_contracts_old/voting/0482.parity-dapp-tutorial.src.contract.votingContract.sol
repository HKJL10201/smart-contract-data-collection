pragma solidity ^0.4.24;

contract Counter {
    event Voted(address indexed who, uint indexed option);

    function vote(uint _option) public {
        if (hasVoted[msg.sender]) revert();
        votes[_option]++;
        hasVoted[msg.sender] = true;
        emit Voted(msg.sender, _option);
    }

    mapping (uint => uint) public votes;
    mapping (address => bool) public hasVoted;
}