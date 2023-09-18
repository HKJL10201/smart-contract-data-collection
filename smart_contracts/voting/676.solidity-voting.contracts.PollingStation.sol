// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@gmussi-contracts/gmussi-claimable/contracts/Claimable.sol";
import "./Poll.sol";

/**
 * This contract allows for the creation and management of Polls
 */
contract PollingStation is Claimable {
    Poll[] public polls;
    mapping (address => uint[]) pollByOwners;

    event PollCreated (address indexed creator, uint indexed pollId, address indexed pollAddr, string name);
    event PollClosed (address indexed pollAddr);

    function createPoll(string memory _name, bytes32[] memory _options) public returns(uint, address) {
        Poll _poll = new Poll(this, _name, _options);
                
        polls.push(_poll);
        uint pollId = polls.length - 1;
        pollByOwners[msg.sender].push(pollId);

        emit PollCreated(msg.sender, pollId, address(_poll), _name);

        _poll.transferOwnership(msg.sender); // why does this fail if I place right after "new"?

        return (pollId, address(_poll));
    }

    function pollClosed(Poll poll) public {
        require(msg.sender == address(poll));

        emit PollClosed(address(poll));
    }

    function getMyPolls() public view returns(uint[] memory) {
        return pollByOwners[msg.sender];
    }

    function getCount() public view returns(uint count) {
        return polls.length;
    }
}