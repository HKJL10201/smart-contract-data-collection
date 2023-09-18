pragma solidity ^0.6.0;

contract Lottery {
    address public manager;
    address payable[] public gamers;
    
    constructor() public {
        manager = msg.sender;
    }
    
    modifier onlyManager() {
        require(msg.sender == manager, "only manager allowed");
        _;
    }
    
    function enter() payable public {
        require(msg.sender != manager , "manager not allowed");
        require(msg.value > 0.01 ether, 'The enter lottery amount must be greater than 0.01 ether');
        gamers.push(msg.sender);
    }
    
    function announceWinner() public onlyManager returns(address) {
        require(gamers.length > 0, "No gamers played at");
        uint winnerIndex = randomNumberGenerator() % gamers.length;
        address winnerAddress = gamers[winnerIndex];
        gamers[winnerIndex].transfer(address(this).balance);
        gamers = new address payable[](0);
        return winnerAddress;
    } 
    
    function getLotterWinnigAmount() public view returns(uint) {
        return address(this).balance;
    }
    
    function getGamersList() public view returns(address payable[] memory) {
        return gamers;
    }
    
    // psuedo random TBH
    function randomNumberGenerator() private pure returns(uint) {
        return uint(keccak256(("any random big number")));
    }
}