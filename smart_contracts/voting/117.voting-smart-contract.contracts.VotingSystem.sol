pragma solidity 0.7.5;
pragma abicoder v2;
import './Voter.sol';

interface WalletInterface{
    function getBalance(address _add) view external returns(uint);
}

contract VotingPortal is VoterPanel{
    
    // Augument of WalletInterface is the address of Wallet contract
    WalletInterface walletInstance = WalletInterface(0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47);
    
    event CreditsEarned(address _voter, uint _creditsEarned);
    
    function earnCredits () public returns(uint) {
        require(voterLog[msg.sender].credits == 0,'Use your remaining credits first');
        uint walletCredits = walletInstance.getBalance(msg.sender);
        require(walletCredits > 0,'To earn credits fill your wallet first');
        voterLog[msg.sender].credits = walletCredits/(1 ether);
        emit CreditsEarned(msg.sender,voterLog[msg.sender].credits);
        return voterLog[msg.sender].credits;
    }
    
    function viewCredits()public view returns(uint){
        return voterLog[msg.sender].credits;
    }
    
    function abs(int x) private pure returns (uint) {
        return x >= 0 ? uint(x) : uint(-x);
    }
    
    //votingPoints = [-credits,credits] , can be negative also
    function vote(uint _pollId,int votingPoints) public {
        
        require(checkStatus[msg.sender][_pollId] != true,"You've already voted for this poll");
        require(pollLogs[_pollId].expirationTime > block.timestamp , "This poll has expired");
        require(votingPoints != 0,'Voting Points can not be zero');
        require(abs(votingPoints) <= voterLog[msg.sender].credits,'Invalid Voting Points');
        
        voterLog[msg.sender].credits = 0;
        voterLog[msg.sender].history.push(VoterHistory(_pollId,votingPoints));
        
        checkStatus[msg.sender][_pollId] = true;
        
        pollLogs[_pollId].voters++;
        pollLogs[_pollId].votes += votingPoints;
        pollLogs[_pollId].result = pollLogs[_pollId].votes/int(pollLogs[_pollId].voters);
        polls[_pollId] = pollLogs[_pollId];
    }
}
