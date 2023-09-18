
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery{
    address payable[] public players;
    address public manager;
    address payable public winner;

    constructor(){
        manager=msg.sender;
    }

    receive() external payable {
        require(msg.value== 1000000000000000, "Minimum entry fee is 1 finney");
        players.push(payable(msg.sender));
    }
    modifier onlyManager{
        require(msg.sender==manager, "only manager has access");
        _;
    }
    function getbalance() onlyManager public view returns (uint)  {
        return address(this).balance;
    }
    function random() internal view returns(uint) {
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    function pickWinner() public onlyManager {
        require(players.length >2,"players are less then 3");
        uint r= random();
        uint index= r % players.length;
        winner= players[index];
        winner.transfer(getbalance());
        players= new address payable[](0);
    }
    function allPlayers() public view returns(address payable[] memory){
        return players;
    }

}
 // gorlieadd: 0xF7341F86133f33c9A3cE29f4F3A4FBB03caF84B2 
//  ganache : 0x60924e3A0c17c6e0AE07ad702faae56cA502473F