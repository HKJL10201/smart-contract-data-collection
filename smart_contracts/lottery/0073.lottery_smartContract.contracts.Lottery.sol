pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address public theWinner;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable{
        
        require(msg.value >= .001 ether);
        
        players.push(msg.sender);
    }
    
    function pickWinner() public managerOnly{
        uint256 indexOfWinner = random() % players.length;
        players[indexOfWinner].transfer(this.balance);
        theWinner = players[indexOfWinner];
        players = new address[](0);
    } 

    function getPlayers() public view returns (address[]) {
        return players;
    }
    
    modifier managerOnly(){
        require(msg.sender == manager);
        _;
    }
    
    //TODO use Chainlink VRF https://docs.chain.link/docs/chainlink-vrf/
    function random() private view returns (uint256){
        uint256 hash = uint(keccak256(block.difficulty, now, players));
        return hash;
    }
}