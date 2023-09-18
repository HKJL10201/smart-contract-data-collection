pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

contract Voting {
  
  struct Voter{
    bool voted;
    bool approval;
  }
  mapping(address => Voter) public voters;
  address public chairperson;
  /* mapping is equivalent to an associate array or hash
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer which used to store the vote count
  */
  mapping (bytes32 => uint8) public votesReceived;
  
  /* Solidity doesn't let you create an array of strings yet. We will use an array of bytes32 instead to store
  the list of candidates
  */
  
  bytes32[] public candidateList;

  // Initialize all the contestants
  // This is the constructor
  function constructor(bytes32[] candidateNames) public {
    candidateList = candidateNames;
    chairperson = msg.sender;
        voters[chairperson].approval = true;
  }

  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    Voter storage sender = voters[msg.sender];
    require(sender.approval, "Not qualified to vote.");
    require(!sender.voted, "Already voted.");
    sender.voted = true;
    votesReceived[candidate] += 1;
  }

  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }

  function giveRightToVote(address voter) public {
        // If the first argument of `require` evaluates
        // to `false`, execution terminates and all
        // changes to the state and to Ether balances
        // are reverted.
        // This used to consume all gas in old EVM versions, but
        // not anymore.
        // It is often a good idea to use `require` to check if
        // functions are called correctly.
        // As a second argument, you can also provide an
        // explanation about what went wrong.
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(!voters[voter].approval);
        voters[voter].approval = true;
    }

}