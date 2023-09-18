pragma solidity ^0.4.23;

import "../GenericModification.sol";

contract EndlessThreshold is GenericModification {
    uint256 approvalThreshold;

    function voteOnModification(uint256 _id, bool _approve)
    public {
        Modification storage m = modifications[_id];
        accountVotes(_id, _approve);
        m.isValid = m.yesTotal >= approvalThreshold;
        inVote[msg.sender].push(_id);
    }
}
