pragma solidity >=0.7.0 <0.9.0;
contract Ballot {

    struct Voter {
        uint weight;
    }

    struct Proposal {
      uint voteCount;
    }

    address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;

    // modifiers
    modifier onlyChair(){
        require(msg.sender == chairperson);
        _;
    }

    modifier validVoter(){
        require(voters[msg.sender].weight > 0, "Not a Registered Voter");
        _;
    }

    constructor (uint numProposals) public { }

    function register (address voter) public onlyChair{ }

    function vote (uint toProposal) public validVoter { }

    function reqWinner() public view returns (uint winningProposal) { }
    
}