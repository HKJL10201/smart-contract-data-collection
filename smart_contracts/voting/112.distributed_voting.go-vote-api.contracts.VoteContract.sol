pragma solidity >=0.7.0;

contract VoteContract {

    mapping(bytes32 => bool) internal _registered_voters;
    mapping(bytes32 => bool) internal _cast_voters;

    function registerVoter(bytes32 _v) public returns (bool){
        if(!_registered_voters[_v]){
            _registered_voters[_v] = true;
            return true;
        }
        return false;
    }

    function checkVoterRegistered(bytes32 _v) public view returns (bool) {
        return _registered_voters[_v];
    }

    function recordVote(bytes32 _v) public returns (bool) {
        if (_registered_voters[_v] && !_cast_voters[_v]){
            _cast_voters[_v] = true;
            return true;
        } 
        
        return false;
    }

    function checkCastVote(bytes32 _v) public view returns (bool) {
        return _cast_voters[_v];
    }

}