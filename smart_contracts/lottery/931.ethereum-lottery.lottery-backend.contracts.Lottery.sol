pragma solidity ^0.4.17;

contract Lottery{
    address public manager; // account address of user creating instance of Lottery contract
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {   // payable anticipates some amount of ether sent along with function call
        require(msg.value > .01 ether);      // used for validation on a boolean parameter
    
        players.push(msg.sender);
    }
    
    function pickWinner() public restricted {
        uint winnerIndex = random() % players.length;
        players[winnerIndex].transfer(this.balance);    // this --> instance of current contract; balance --> total ether in contract
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
    
    function random() private view returns (uint){     // only want random function viewable within contract
        return uint(keccak256(block.difficulty, now, players));
    }
    
    modifier restricted() {
        require(msg.sender == manager);     // enforce security that only manager of contract can call method successfully
        _;
    }
}