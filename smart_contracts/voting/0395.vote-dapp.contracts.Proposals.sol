// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Voters.sol";
import "./Ownable.sol";
import "./functools.sol";

contract Proposals is Voters, Ownable, functools {
    uint256 counter;

    function submitTopic(string memory topic) public onlyOwner {
        openForProposal[topic] = true;
        topicsOnAgenda[counter] = topic;
        counter += 1;
    }

    function removeTopic(uint256 index) public onlyOwner {
        require(index <= counter, "out of range index");
        topicsOnAgenda[index] = "topic removed.";
    }

    function submitProposal(
        string memory topic,
        string memory dateProposed,
        string memory proposal
    ) public isRegistered proposalsAllowed(topic) {
        proposalsPutForward[msg.sender][topic] = Proposition({
            proposition: proposal,
            proposedBy: msg.sender,
            dateProposed: dateProposed
        });

        putForwardProposal[msg.sender] = true;
        emit newProposal(msg.sender, "you've put forward a new proposal");
    }

    function readProposition(address candidate, string memory topic)
        public
        view
        returns (string memory)
    {
        return proposalsPutForward[candidate][topic].proposition;
    }

    modifier proposalsAllowed(string memory topic) {
        require(
            openForProposal[topic] == true,
            "Due date for proposal acceptence is closed."
        );
        _;
    }
    mapping(string => bool) public openForProposal;
    mapping(uint256 => string) public topicsOnAgenda;
    mapping(address => bool) public putForwardProposal;
    mapping(address => mapping(string => Proposition))
        internal proposalsPutForward;

    event newProposal(address indexed candidate, string indexed message);
    event ProposalsUpdated(address indexed candiate, string indexed message);
}
