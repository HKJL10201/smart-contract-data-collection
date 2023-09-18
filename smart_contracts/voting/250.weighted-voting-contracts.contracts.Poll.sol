pragma solidity ^0.4.19;

import './iPoll.sol';
import './Owner.sol';
import './iToken.sol';

contract Poll is iPoll, Owner {
    function () public {
        /// if ether is sent to this address, send it back.
        revert();
    }

    address public group;
    string public name;
    string public description;

    struct Vote {

    }

    function Poll() public {
        /// TODO: implement. Create new poll
    }

    function vote() public returns (bool success) {
//        address[] memory addressIndices = TokenInterface(group).getMembers();
//        for (uint i=0; i<addressIndices.length; i++) {
//            if (addressIndices[i] == msg.sender) {
//                /// TODO: cast vote
//                return true;
//            }
//        }
//        /// Sender is not a member of a group
//        return false;
        return true;
    }

    function closePoll() public onlyOwner returns (bool success) {
        /// TODO: implement. Close the poll
        return true;
    }
}
