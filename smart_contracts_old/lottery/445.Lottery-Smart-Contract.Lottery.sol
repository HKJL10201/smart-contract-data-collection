contract Lottery{
    address public manager;
    address payable[]  public  players;
    
    constructor()public{
        manager = msg.sender;
    }
    modifier OnlyManager(){
        require(manager == msg.sender);
        _;
    }
    function Enter()public payable{
        require(msg.value > 1 ether);
        players.push(msg.sender);
    }
    function Ramdom() public view OnlyManager returns(uint){
       uint(keccak256(abi.encodePacked(block.difficulty,now,players)));
    }
    function PickWinner()public OnlyManager payable {
        uint index = Ramdom() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }
    // return list address attended in process
    function GetPlayer() public view returns (address payable[] memory){
        return players; 
    }
}