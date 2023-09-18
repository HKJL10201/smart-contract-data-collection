//"SPDX-License-Identifier: UNLICENSED" 

pragma solidity >=0.7.0 <0.9.0;

contract Dice {

    uint256 number;
    uint balance;

    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }

    function refil() public payable {
        balance += msg.value;
    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    function withdrawMoney() public {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
    function dice(uint8 num) public payable {
        require(msg.value == 3 ether, "payment value has to 3 ether");
        address payable to = payable(msg.sender);
        to.transfer(num * 1 ether);
    }

    // unfortunately gives same value every time it is called
    // function randomDice() public view returns (uint) {
    //     uint256 seed = uint256(keccak256(abi.encodePacked(
    //     block.timestamp + block.difficulty +
    //     ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
    //     block.gaslimit + 
    //     ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
    //     block.number
    //     )));

    // return (seed - ((seed / 1000) * 1000)) % 6;
    // }
}