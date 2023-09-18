pragma solidity ^0.4.17;
contract VotingSystem {
    struct Voter {
        bool registered;
        bool voted;
        uint8 vote_to;
    }
    modifier onlyDeployer () {
      require(msg.sender == chairperson);
      _;
    }
    address public chairperson;
    mapping(address => Voter) public voters;
    uint[4] public parties;
    
    constructor() public {
        chairperson = msg.sender;
    }

    function register(address toVoter) public onlyDeployer{
        if(voters[toVoter].registered == true) revert();
        voters[toVoter].voted = false;
        voters[toVoter].registered=true;
    }

    function vote(uint8 toProposal) public {
        Voter storage sender = voters[msg.sender];
        if (sender.voted || toProposal >= 4 || sender.registered == false) revert();
        sender.voted = true;
        sender.vote_to = toProposal;
        parties[toProposal] ++;
    }

    function winningParty() public constant returns (uint8 _winningParty) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < 4; prop++)
            if (parties[prop] > winningVoteCount) {
                winningVoteCount = parties[prop];
                _winningParty = prop;
            }
    }
}
