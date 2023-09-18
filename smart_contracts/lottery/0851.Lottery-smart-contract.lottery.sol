//SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0;
contract LOttery{
address public manager;
address payable[] public users;

constructor()
{
    manager=msg.sender;
}
receive() external payable{
    require(msg.value==1 ether);
    users.push(payable(msg.sender));

}
function getBalance() public view returns(uint)
{
    require(msg.sender==manager);
    return address(this).balance;
}
function random() public view returns(uint){
    return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,users.length)));
}
function selectWinner() public 
{
    require(msg.sender==manager);
    require(users.length>=3);
    uint r=random();
    address payable winner;
    uint index = r % users.length;
    winner=users[index];
    winner.transfer(getBalance());
    users=new address payable[](0);
}
}
