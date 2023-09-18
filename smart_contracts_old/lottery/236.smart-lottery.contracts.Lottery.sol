pragma solidity ^0.4.17;

contract Lottery {
    // 将来的には　Ownable を継承する
    address public contractOwner;
    address[] public participants;
    uint public voteFee;

    constructor() public {
        contractOwner = msg.sender;
        voteFee = 0.01 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    modifier validEntry() {
        require(msg.value > voteFee);
        _;
    }

    function randMod() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, participants));
    }

    function changeVoteFee(uint _fee) public onlyOwner {
        voteFee = _fee;
    }

    function participate() public payable validEntry {
        participants.push(msg.sender);
    }

    function viewEntries() public view returns (address[]) {
        return participants;
    }

    function viewAmmount() public view returns(uint) {
        return this.balance;
    }

    function excuteLottery() public onlyOwner {
        uint winnerIndex = randMod() % participants.length;
        participants[winnerIndex].transfer(this.balance);
        participants = new address[](0);
    }
}