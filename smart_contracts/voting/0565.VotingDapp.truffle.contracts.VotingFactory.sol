// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

import "./Voting.sol";

contract VotingFactory is Ownable {

    struct VoteSession {
        string description;
        address voteContractAdress;
    }

    mapping(address => VoteSession[]) userVoteSessions;

    function getMyVotingSessions() external view returns(VoteSession[] memory) {
        return userVoteSessions[msg.sender];
    }

    function createVotingSession(string calldata _description) external {
        Voting newVotingSession = new Voting();
        newVotingSession.setDescription(_description);
        newVotingSession.transferOwnership(msg.sender);

        VoteSession memory voteSession;
        voteSession.description = _description;
        voteSession.voteContractAdress = address(newVotingSession);

        userVoteSessions[msg.sender].push(voteSession);
    }
}