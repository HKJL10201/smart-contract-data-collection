//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    address payable[] public players;
    address manager;
    address payable public winner;
    
    constructor(){
        manager=msg.sender;
    }
    receive() external payable{
        require(msg.value==1 ether,"please pay 1 ether only");
        players.push(payable(msg.sender));
    }

    function getbalance() public view returns(uint){
        require(manager==msg.sender,"you are not the manager");
        return address(this).balance;
    }
    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    function pickWinner() public {
        require(manager==msg.sender,"you are not the manager");
        require(players.length>=3,"players are less than 3");
        uint r=random();
        uint index=r%players.length;
        winner=players[index];
        winner.transfer(getbalance());
        players=new address payable[](0);
    }
    function allPlayers() public view returns(address payable[] memory){
        return players;
    }
}//0x1262b813E4471684996212ea7C49CC3Caf5A8506
//0x4341DBFe2C95F31Cb34C7B2084153766b405AE90  -- ganache