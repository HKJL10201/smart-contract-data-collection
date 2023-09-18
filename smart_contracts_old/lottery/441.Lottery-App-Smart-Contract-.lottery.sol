pragma solidity ^0.4.17;
contract Lottery {
    address company;
    address[] public players;
    address public winner;
    uint8 public counter=0;
    function Lottery() public{
        company=msg.sender;
    }
    function enter_lottery() public payable{
        players.push(msg.sender);
        require(msg.value>=0.01 ether);
    }
    function random() private view returns (uint8) {
       return uint8(uint256(keccak256(block.timestamp, block.difficulty))%251);
   }
    function pick_winner() public{
        require(msg.sender==company);
        uint256 playerindex= random()%players.length;
        winner=players[playerindex];
        require(counter==0);
        winner.transfer(this.balance*7/10);
        company.transfer(this.balance);
        counter = 1;
    }
}
