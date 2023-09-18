//SPDX-Licensce-Identifier : GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;

contract lottery
{
    address payable[]public players;
    address owner;
    address payable public winner;
    constructor()
    {
        owner=msg.sender;
    }

    receive()external payable
    {
        require(msg.value==0.001 ether,"Please Provide atleast 0.001 Ether");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint)
    { 
         require(msg.sender==owner,"Sorry,You Cant Check the Balance");
        return address(this).balance;
    }

    function random()internal view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.timestamp,players.length)));
    }
  
    function pickWinner()public 
    {
        require(msg.sender==owner,"only Owner can Pick Winner");
        require(players.length>=3,"Not have Enough ParticiPants");
        uint r= random();
        uint index=r % players.length;
       winner=players[index];
       winner.transfer(getBalance());
       players=new address payable[](0);
    }

    function allPlayers()view public returns(address payable[] memory)
     {
         return players;
     }
}

// 0x310fdC3A678DBDA26d5723277085D3bACC1Ef2f0