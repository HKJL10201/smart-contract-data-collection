pragma solidity >=0.5.0 <0.6.0;

contract vote {
    struct ballot{
        string candidate;
        string item;
        bool sent;
    }
    function write_candidate(ballot storage paper, string memory result) internal {
        paper.candidate = result;
    }
}