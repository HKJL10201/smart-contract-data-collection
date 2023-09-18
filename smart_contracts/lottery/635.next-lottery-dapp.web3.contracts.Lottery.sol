//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Lottery {
    /**
     * owner = address of contract owner
     * players = array of players who joined
     * lotteryId = id of the lottery
     * lotteryHistory = every key will be associated to an address
     */
    address public owner;
    address payable[] public players;
    uint256 public lotteryId;
    uint256 public randomResult;
    mapping(uint256 => address payable) public lotteryHistory;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    function getWinnerByLotteryId(uint256 lotteryId_)
        public
        view
        returns (address payable)
    {
        return lotteryHistory[lotteryId_];
    }

    function getRandomResult() public view returns (uint256) {
        return randomResult;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > .01 ether, "Transfer .01 ether to join.");
        players.push(payable(msg.sender));
    }

    function getRandomNumber() public view returns (uint256) {
        // https://stackoverflow.com/questions/48848948/how-to-generate-a-random-number-in-solidity
        return uint256(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function pickWinner() public onlyOwner {
        randomResult = getRandomNumber();
    }

    function payWinner() public onlyOwner {
        require(randomResult > 0, "Must pick winner first.");
        uint256 index = randomResult % players.length;
        players[index].transfer(address(this).balance);

        lotteryHistory[lotteryId] = players[index];
        lotteryId++;

        // reset the state of the contract
        players = new address payable[](0);
        randomResult = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can invoke this.");
        _;
    }
}
