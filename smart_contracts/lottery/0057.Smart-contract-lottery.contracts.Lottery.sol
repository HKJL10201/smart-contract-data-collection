pragma solidity ^0.4.17;

contract Lottery{
    address public manager ;
    address [] public  players;

    function Lottery () public {
        manager =  msg.sender;
    }
    function getManager () public view returns(address){
        return manager;
    }
    function enter() public payable {
        require(msg.value==1 ether);
        players.push(msg.sender);
    }
    function getPlayer()public view returns(address[]){
        return players;
    }
    function getBalance ()public view returns(uint){
        return this.balance;
    }
    function getPlayerCount()public view returns (uint){
        return players.length;
    }
    function random ()private view returns (uint){
        return uint(keccak256(block.difficulty,now,players));
    }
    function pickWinner()public onlyManager returns(address){
        uint index = random()%getPlayerCount();
        address winner = players[index];
        winner.transfer(this.balance);
        players = new address[](0);
        return winner;

    }
    function refund () public  onlyManager{

        for(uint i = 0;i<players.length ;i++){
            players[i].transfer(1 ether);
        }
        players= new address[](0);
    }
    modifier onlyManager {
        require(msg.sender==manager);
        _;
    }
}