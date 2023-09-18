pragma solidity ^0.4.0;
contract SmartVote {
    address dictator;
    bool dictatorVote;
    
    function dictatorVoting(bool vote) public {
        dictatorVote = vote;
    }
    
    function voteResult() public constant returns (bool _voteResult) {
        _voteResult = dictatorVote;
    }
    
}
