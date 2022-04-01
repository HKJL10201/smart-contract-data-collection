pragma solidity ^0.4.17;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';

contract GenesisVisionVoting is Ownable {
    enum VotingState { Created, VotingStarted, VotingFinished }

    event VotingStarted();
    event VotingFinished();
    event NewVote(address holder, uint8 proposalNumber);

    ERC20Basic gvToken = ERC20Basic(0x103c3A209da59d3E7C4A89307e66521e081CFDF0);

    VotingState public votingState = VotingState.Created;

    function StartVoting() onlyOwner external {
        votingState = VotingState.VotingStarted;
        emit VotingStarted();
    }

    function FinishVoting() onlyOwner external {
        votingState = VotingState.VotingFinished;
        emit VotingFinished();
    }

    function Vote(uint8 proposalNumber) external {
        require(votingState == VotingState.VotingFinished)
        require(gvToken.balanceOf(msg.sender) > 0);
        require(proposalNumber > 0 && proposalNumber < 6);

        emit NewVote(msg.sender, proposalNumber);
    }
}