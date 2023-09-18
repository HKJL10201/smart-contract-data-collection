pragma solidity >=0.4.22 <0.6.0;

contract Lottery{
    address public manager;
    address payable[] players;    

    modifier onlyManager{
        require(msg.sender == manager, "Wrong calling! Only manager can call the function");
        _;
    }
    
    constructor() public{
        manager = msg.sender;
    }
    
    function enter() public payable{
        require(msg.value > .01 ether);        
        players.push(msg.sender);
    }
    
    function random()public view returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }
    
   function pickWinner() public onlyManager{
        uint256 index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);          
    }
    
    function getPlayers() public view returns(address payable[] memory){
        return players;
    }
}