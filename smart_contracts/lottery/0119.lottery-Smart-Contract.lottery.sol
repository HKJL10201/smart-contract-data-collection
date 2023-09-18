// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract lottery{

    address public manager;

    address payable[] public users;

    constructor(){
        manager = msg.sender; //Global Variable 
    }

    receive() external payable{

        require(msg.value == 2 ether); // Amount should not less then 2 Eth
        users.push(payable(msg.sender));

    }

    function checkBal() public view returns(uint){
        require(msg.sender==manager);
        return address(this).balance;
    }

    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, users.length)));
    }
    
    function selectWinner() public {

        require(msg.sender == manager);
        require(users.length>=3);
        uint r = random();
        address payable winner;
        uint index = r % users.length;
        winner = users[index];  
        winner.transfer(checkBal());
        users = new address payable[](0); //Smart Contract Balance will be 0 when random users seleceted winner 

    }

}
