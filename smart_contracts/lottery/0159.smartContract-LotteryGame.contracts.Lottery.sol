pragma solidity 0.4.17;

contract Lottery {
    
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether); // enter game with more than .01 eth
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players)); //generate random pseudo number with current blc_diff, timestamp and players
    }
    
    function pickWinner() public isManager {
        
        uint index = random() % players.length; //pick winner by modulus of random() divided by address aray length
        players[index].transfer(this.balance); //transfer contract ether to winner
        players = new address[](0); // reset our contract address to size 0, after awarding a winner
    }
    
    modifier isManager() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}