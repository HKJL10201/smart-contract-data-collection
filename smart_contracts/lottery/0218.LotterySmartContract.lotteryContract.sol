pragma solidity ^0.5.6;

contract Lottery 
   {
    address public manager;
    address payable[] public players;
    event winnerEvent (address winner, uint amount);
    constructor() public 
    {
        manager = msg.sender; // The person who deploys the contract is the manager.
    }
    modifier onlyManager()
    {
        require(manager == msg.sender,"Only the manager can call this fn");
        _;
    }
    function () payable external
    {
        require(msg.value >= 0.01 ether); // Minimum amount of ether required for lottery is 0.01
        require(manager != msg.sender); // The manager cannot withdraw the money for himself
        players.push(msg.sender);
    }
    function balance() public view onlyManager returns (uint) // Only the manager can view the total amount present in the lottery contract
    {
        //require(manager == msg.sender,"Only the manager can call balance");
        return address(this).balance;
    }
    function random() public view returns(uint) 
    {
        return uint(keccak256(abi.encodePacked(block.timestamp,players.length)));
        //returns a very big pseudo-random integer number
    }
    function selectWinner() public onlyManager // winner can be selected only by the manager
    {
        //require(manager == msg.sender,"Only the manager can call winner");
        uint r = random(); // rondomization functions are not available in smart contract
        address payable winner; // The total amount present in the contract is transferred to the winner
        uint index = r % players.length;
        winner = players[index];
        require(manager != winner); // The winner should not be manager
        emit winnerEvent(winner,address(this).balance);
        winner.transfer(address(this).balance);
        players = new address payable[](0);
        //emit winnerEvent(winner,address(this).balance);
    }
}
