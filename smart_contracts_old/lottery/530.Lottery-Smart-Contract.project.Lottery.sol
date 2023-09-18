pragma solidity ^0.4.20;
contract Lottery {
    address owner;
    uint8 cost;
    uint256 playdeadline;
    uint256 revealdeadline;
    address [] public listofwinners;
    uint256 public winning_number;
    
    
    mapping(address => bytes32) played;
    

    function Lottery( uint256 play_deadline, uint256 reveal_deadline) public{
        owner = msg.sender;
        playdeadline = play_deadline;
        revealdeadline = reveal_deadline;
    }
    

    
    function play (bytes32 h) external payable {
        require(msg.value >= .01 ether);
        played[msg.sender] = h;
        
    }
    function winning (uint256 _winning_number) external {
        require (msg.sender == owner);
        winning_number = _winning_number;
    }
    
    function reveal (uint256 r) external {
        //require( now > revealdeadline);
        bytes32 h = sha256(winning_number, r);
        require (played[msg.sender] == h);
        msg.sender.transfer(this.balance);
        listofwinners.push(msg.sender);
    }
    

    function test_bytes32 (bytes32 n) public pure returns (bytes32) {
    return sha256 (n);
}
    function done () external {
    for (uint i=0; i < listofwinners.length; i++) {
        uint winningParticipants = listofwinners.length;
        listofwinners[i].transfer(this.balance / winningParticipants);
        i++;
        }
        uint ownermoney = this.balance / listofwinners.length;
        owner.transfer(ownermoney);
        
}
}