// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ChristmasLottery {
    uint32 public maxNumber;
    uint public price;
    address owner;

    mapping(address => uint[]) public userNumbers;
    mapping(uint => address payable) numberUser;
    mapping(uint => bool) purchasedNumbers;

    constructor(uint _price) {
        maxNumber = 99999;
        price = _price;

        owner = msg.sender;
    }

    event NumbersPurchased(address purchaser, uint[] numbers);
    event WinnerRewarded(address winner, uint number, uint prize);

    function purchase(uint[] memory _numbers) public payable {
        require(_numbers.length >= 1, 'At least one number, cabron!');
        require(msg.value == _numbers.length * price, 'Numbers have to be paid!');

        for (uint256 index = 0; index < _numbers.length; index++) {
            uint _number = _numbers[index];

            require(_number <= maxNumber, 'Number out of bounds!');
            require(!purchasedNumbers[_number], 'Number is not available!');

            userNumbers[msg.sender].push(_number);
            numberUser[_number] = payable(msg.sender);
            purchasedNumbers[_number] = true;
        }

        emit NumbersPurchased(msg.sender, _numbers);
    }

    function rewardWinner(uint _number) public {
        require(owner == msg.sender, 'Forbidden!');
        address payable winner = numberUser[_number];
        uint totalBalance = address(this).balance;

        winner.transfer(totalBalance);

        emit WinnerRewarded(winner, _number, totalBalance);
    }

    function getUserNumbers() public view returns (uint[] memory) {
        return userNumbers[msg.sender];
    }

    function getTotalBalance() public view returns (uint) {
        return address(this).balance;
    }

    function isNumberAvailable(uint _number) public view returns (bool) {
        return numberUser[_number] == address(0x0);
    }
}
