pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    address chairperson;
    
    struct Voter {

    }

    struct Proposal {
 
    }

    mapping(address => Voter) voters;
    Proposal[] proposals;

    /** Gate Keepers */
    modifier onlyChair() {
        require(chairperson == msg.sender);
        _; /** Continue execution of actual logic guarded by this modifier */
    }

    /* A voter who is registered will have his/her weight > 0 */
    modifier validVoter() {
        require(voters[msg.sender].weight > 0, "Not a registered voter");
        _;
    }

    constructor(uint numProposals) public {}

    function register(address voter) public onlyChair {}

    function vote(uint toProposal) public validVoter {}

    function reqWinner() public view returns (uint winningProposal) {}

}