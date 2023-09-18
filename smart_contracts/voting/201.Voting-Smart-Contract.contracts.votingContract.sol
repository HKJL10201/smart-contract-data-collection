// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title Voting Contract
/// @author Joseph Adewunmi
/// @notice A voting contract that allows

contract votingContract {
  ///Define the Persona of a user with all possible features
  /// @inherit doc	Copies all missing tags from the base function (must be followed by the contract name)

    struct Voter{
      uint weight;
      bool voted;
      address delegate;
      uint vote;
    }

    struct Proposal {
      bytes32 name;
      uint votecount;
    }

    address public chairPerson;
    
    Proposal [] public allProposals;

    mapping (address=>Voter) public Voters;

  constructor(bytes32 ProposalNames) public {
    chairPerson = msg.sender; // The chairperson is the sender
    Voters[chairPerson].weight = 1;

    for (uint i = 0; i < ProposalNames.length; i++) { 
      /// @notice Explain to an end user what this does
      /// @dev Explain to a developer any extra details
      /// @return Documents the return variables of a contract’s function state variable
      /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)

      allProposals.push(Proposal({name:ProposalNames[i],votecount:0}));
    }
  }

    function allowToVote (address voter) external {
      /// @notice Explain to an end user what this does
      /// @dev Explain to a developer any extra details
      /// @param Documents a parameter just like in doxygen (must be followed by parameter name)
      /// @return Documents the return variables of a contract’s function state variable
      /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
      require(chairPerson == msg.sender,"Only Admin has the right to Vote");
      require(!Voters[voter].voted,"Voter already Voted");
      require(Voters[voter].weight == 0);
      Voters[voter].weight = 1;
    }


    function delegate(address to) external{
      Voter storage sender = Voters[msg.sender];

      require(!sender.voted,"You've Voted Already");

      require(to != msg.sender,"You cant delegate to yourself");

      while (Voters[to].delegate != address(0)){
        to = Voters[to].delegate;
        require(to != msg.sender);
      }
      
      sender.voted=true;
      sender.delegate = to;

      Voter storage delegate_ = Voters[to];

      if(delegate_.Voted){
        Proposal[delegate_.vote].votecount =+ sender.weight;
      }

      else{
        delegate_.weight += sender.weight;
      }
    }

    function vote(uint proposal){
      /// @notice Explain to an end user what this does
      /// @dev Explain to a developer any extra details
      /// @param Documents a parameter just like in doxygen (must be followed by parameter name)
      /// @return Documents the return variables of a contract’s function state variable
      /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)

      Voter storage sender = Voters[to];
      require(sender.weight !=0, "has no right to vote");
      require(!sender.voted,"Already Voted");
      sender.vote = true;
      sender.vote = proposal;
      Proposal[proposal].votecount;
    }

    function winningProposal() view public returns (uint winningProposal_) {
      /// @notice Explain to an end user what this does
      /// @dev Explain to a developer any extra details
      /// @param Documents a parameter just like in doxygen (must be followed by parameter name)
      /// @return Documents the return variables of a contract’s function state variable
      /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)

      uint winningProposal = 0;
    for (uint256 p = 0; p < allProposals.length; p++) {
      if (allProposals[p].votecount > winningProposal){
        winningProposal += allProposals[p].votecount;
        winningProposal_=p;
      }
    }      
  }

  function winningProposalName() external returns (bytes32 _winnerName) {
    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param Documents a parameter just like in doxygen (must be followed by parameter name)
    /// @return Documents the return variables of a contract’s function state variable
    /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)

    _winnerName = allProposals[winningProposal()].name;   
  }
}
