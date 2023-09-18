// SPDX-License-Identifier: GLP-3.0

pragma solidity >=0.8.7 <0.9.0;

contract Lotery {
    uint256 public minFee;
    address owner;
    address[] players;
    mapping(address => uint256) public playerBalances;

    constructor(uint256 _minFee) {
        minFee = _minFee;
        owner = msg.sender;
    }

    function play() public payable minFeeToPay {
        players.push(msg.sender);
        playerBalances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRandomNumber() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function pickWinner() public onlyOwner {
        uint256 index = getRandomNumber() % players.length;
        (bool success, ) = players[index].call{value: getBalance()}("");
        require(success, "Payment fail, try again please");
        players = new address[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier minFeeToPay() {
        require(msg.value >= minFee, "You need invest at least 1ETH");
        _;
    }
}
