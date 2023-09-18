pragma solidity ^0.4.17;

contract Lotto {
    // intialize manager variable
    address public manager;
    // initialize players array
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable{
        //used for validation, pass boolean as argument 
        require(msg.value > .01 ether);
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint){
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        //validates manager 
        // require(msg.sender == manager);
        
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }
    
    // function returnEntries() {
    //     require(msg.sender == manager);
    // }
    //created modifier to reuse manager validation 
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}