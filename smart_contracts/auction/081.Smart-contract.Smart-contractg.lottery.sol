pragma solidity 0.6.0;

contract lottery{
    address public owner;
    uint256 private latestBlockNumber;
    bytes32 private cumulativeHash;
    address[] private bets;
    mapping(address => uint) winners;
    
    constructor() public{
        owner = msg.sender;
        latestBlockNumber = block.number;
    cumulativeHash = bytes32(0);
    }
    
    modifier onlyowner(){
        
        require(msg.sender == owner);
        _;
    }
    
    function placebet() public payable returns(bool){
       uint256 teth = msg.value;
       assert(teth == 0.5 ether);
       cumulativeHash = keccak256(abi.encodePacked(latestBlockNumber, cumulativeHash));
       latestBlockNumber = block.number;
       bets.push(msg.sender);
       return true;
    }
    
    function draw_winner() public onlyowner returns(address){
        assert(bets.length >=4);
        latestBlockNumber = block.number;
        bytes32 finalhash = keccak256(abi.encodePacked((latestBlockNumber-1), cumulativeHash));
       uint256 _random =    uint256(finalhash) % bets.length;
        address winner = bets[_random];
        winners[winner] = 1 ether * bets.length;
        cumulativeHash = bytes32(0);
        delete bets;
        return winner;
       
    }
    
    function withdraw() public returns(bool){
        uint256 amount = winners[msg.sender];
        winners[msg.sender] = 0;
        if(msg.sender.send(amount)){
            return true;
        }
        else{
            winners[msg.sender] = amount;
            return false;
            
        }
    }
    
    function getbets(uint betnumber) public view returns(address){
        return bets[betnumber];
    }
    function get_noof_bets( ) public view returns(uint){
        return bets.length;
    } 
}
