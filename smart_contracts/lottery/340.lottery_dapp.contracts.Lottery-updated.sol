//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract Lottery {
    
    address public manager;
    address payable[] public players;//methods like .transfer(),send(),can only be called with address payable type
    address  public last_winner;
    constructor() {
        manager=msg.sender;
    }
    function enter()public payable{
        require(msg.value>.01 ether);
        players.push(payable(msg.sender));
    }
    function random() private view returns (uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }
    function pickwinnder() public restricted{
        uint index=random()%players.length;
        players[index].transfer(address(this).balance);
        last_winner=players[index];
        players= new address payable[](0);
    }
    modifier restricted(){
        require(msg.sender==manager);
        _;
    }

    function getPlayers() public view returns(address payable[] memory){
        return players;
    }
    function getWinner() public view returns(address)
    {
        return last_winner;
    }

}