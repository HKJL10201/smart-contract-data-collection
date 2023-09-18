pragma solidity ^0.4.24;

// small aux contract for v0101 delegation to add some features
contract SVDelegationV0101Aux {
    mapping (address => uint256) public delegationsRevokedBefore;

    function revokePastDelegations() public {
        delegationsRevokedBefore[msg.sender] = block.number;
    }
}
