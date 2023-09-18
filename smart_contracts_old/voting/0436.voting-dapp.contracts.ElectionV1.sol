pragma solidity >=0.4.21 < 0.6.0;

import "./ElectionStorage.sol";

contract ElectionV1 {

    ElectionStorage public electionStorage;

    constructor (ElectionStorage _electionStorage) public {
        require(_electionStorage != address(0));
        electionStorage = _electionStorage;
    }

    function vote (uint _candidateId) public {
        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= electionStorage.candidatesCount());

        // update candidate vote count
        require(electionStorage.increaseVoteCount(_candidateId));
    }
}