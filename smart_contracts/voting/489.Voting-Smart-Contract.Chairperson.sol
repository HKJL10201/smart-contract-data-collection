pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "./Ballot.sol";
/* Smart Contract that deploys, and manages the Ballot Smart Contract (providing the list of candidates, starting and ending the vote period, ...) */
contract Chairperson {

    address _owner;

    Ballot public _ballot ;
    constructor() {
        _owner = msg.sender;
        _ballot = new Ballot();
    }

    function setCandidateList(string[] memory candidateList) external onlySmartContractOwner {
        require(currentState() == Ballot.State.Created, "Ballot state must be on Created");
        _ballot.addCandidates(candidateList);
    }

    function getCandidateList() 
    public view 
    returns(Ballot.Candidate[] memory candidates){
        return _ballot.getCandidateList();
    }

    function startVote() external onlySmartContractOwner { //call this method at a certain predefined time
        _ballot.startVote();
    }

    function endVote() external onlySmartContractOwner { //call this method at a certain predefined time
        _ballot.endVote();
    }

    function currentState() public view
        returns (Ballot.State state) {
        return _ballot.state();
    }

      modifier onlySmartContractOwner() {
        require(
            msg.sender == _owner,
            "Only chairperson can start and end the voting"
        );
        _;
    }
}
