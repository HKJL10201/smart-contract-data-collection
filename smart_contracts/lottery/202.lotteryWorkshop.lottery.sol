pragma solidity ^0.4.23;
contract Lottery{

    event Winer(string name, uint pass);

    struct Member{
        string name;
        uint pass;
    }

    address owner;
    Member [] public players;
    Member [] public winners;
    mapping(uint => bool) public passUsed;


    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

constructor() public{
owner = msg.sender;
}

function enter(string _name, uint _pass) public payable{ // external
require(msg.value == 0.1 ether);
require(!passUsed[_pass]);
passUsed[_pass] = true;

Member memory player = Member({ //  players.push(Member(_name, _pass));
name: _name,
pass: _pass
});
players.push(player);
}

function getWiner() public onlyOwner{

uint winnerIndex = uint(keccak256(now, blockhash(block.number-1))) % players.length;
Member memory winner = players[winnerIndex];

winners.push(winner);
players[winnerIndex] = players[players.length-1]; // заменяем место победителя последним
players.length = players.length -1; // удаляем последнего полностью (delete только обнуляет)

emit Winer(winner.name, winner.pass);
}


function getPlayersLength() public view returns(uint){
return players.length;
}

function getWinnersArr() public view returns(uint[]){
uint[] memory arrPass = new uint[](winners.length);
for(uint i = 0; i < winners.length; i++) {
arrPass[i] = (winners[i].pass);
}
return arrPass;
}

function getBalance() public view returns(uint){
return address(this).balance;
}

function withdrow() public onlyOwner{
msg.sender.transfer(address(this).balance);
}


}




