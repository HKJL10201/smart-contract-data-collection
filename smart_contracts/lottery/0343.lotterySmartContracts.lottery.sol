//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.16;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lottery is IERC20{

    address public winner;
    address public manager; //manager is in charge of the contract
 
    address[] public players = [0xFcD51fe49C072a5CBF4426EcA223db415e763564,
    0x62C9511E06b0Aca785e69B5f81c29DF4AfB4F71B,
    0x075D29D70FF3d5AD1a2569bba6F581CBf2be7Cee]; // Players array
    address[] public winnersArray;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {}

    function random() public view returns(uint){
        return uint (keccak256(abi.encode(block.timestamp, players)));
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function arrayLength() public view returns (uint) {
        uint lenght = winnersArray.length;
        return lenght;
    }

    function approve(address delegate, uint256 _amount) public returns (bool) {
        require(msg.sender == manager , "You are not the manager");
        emit Approval(msg.sender, delegate, _amount);
        return true;
    }

    //------------------Select Winners

    function firstWinner() public restricted {
        uint index = random() % players.length;
        winner = players[index];
        winnersArray.push(winner);
    }

    function secondWinner() public restricted {
        uint index = (random() + 2) % players.length;
        winner = players[index];
        winnersArray.push(winner);
    }

    function thirdWinner() public restricted {
        uint index = (random() + 3) % players.length;
        winner = players[index];
        winnersArray.push(winner);
    }

    function getWinners() public restricted {
        firstWinner();
        secondWinner();
        thirdWinner();
    }
    
    //------------------

    function sendAwards() public payable {
        require(msg.sender == manager , "You are not the manager");

        // pays the winner picked randomely(not fully random)
        payable (winnersArray[0]).transfer(address(this).balance / 100 * 50);
        payable (winnersArray[1]).transfer(address(this).balance / 100 * 60);
        payable (winnersArray[2]).transfer(address(this).balance);

        // empies the old lottery and starts new one
        players = new address[](0);
        winnersArray = new address[](0);
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

}