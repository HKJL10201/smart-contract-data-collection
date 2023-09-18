// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Lottery {
    address payable[] public players; // dynamic with players address
    address public manager = msg.sender;
    
    // This event is belong to the receive payable function
    event Received(address, uint);
    
     // This receive payable function will automatically called when somebody sends ethers to our contract address and it is use in place
     // of fallback function.
    receive() external payable {
        require(msg.value >= 0.01 ether);
        emit Received(msg.sender, msg.value);
        players.push(msg.sender);
    }
    
    function get_balance() public view returns(uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }
    
    function random() public view returns(uint) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function selectWinner() public {
        require(msg.sender == manager);
        uint randomNumber = random();
        
        address payable winner;
        uint index = randomNumber % players.length;
        winner = players[index];
        
        winner.transfer(address(this).balance);
        
        players = new address payable[](0);
    }
}
