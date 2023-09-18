// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract Lottery{
    address public manager;
    address [] public players;
    constructor(){
        manager=msg.sender;
    }
    function enter() public payable{
        // for(uint i=0;i<players.length;i++){
            // require(msg.sender!=players[i],'409: player is already regis/tered');
            require(msg.value > 0.01 ether,'410: need at least 0.01 ether');
            players.push(msg.sender);
        // }
    }
    function random() private view returns (uint){
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, players)));
    }
    function pickWinner() restricted public{
        
        uint index=random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        delete players;
    }
    modifier restricted(){
        require(msg.sender==manager,'401: only manger can access it');
        _;
    }
    function getPlayers() public view returns(address[] memory)
    {
        return players;
    }
}