pragma solidity >=0.4.22 <0.8.0;

// pragma experimental ABIEncoderV2;

contract Voting {
  /* VARIABLES */
  //STRUCTS
  struct Proposal {
    uint256 yesCount;
    uint256 noCount;
    uint256 totalVotes;
  }

  struct Voter {
    bool voted;
    address voterAddress;
    bool[] choices;
  }

  //Arrays
  Proposal[] proposals;
  bool[] winningProposals;

  //MAPPING
  mapping(address => Voter) voters;

  //UINTS
  uint256 totalRegisteredVoters;

  //ADDRESSES
  address electionOfficial;

  //EVENTS
  event VoteCast(address _voter);
  event Registered(address _voter);
  event VotesCounted(
    uint256 indexed _totalVotes,
    uint256 indexed _yesCount,
    uint256 indexed _noCount
  );

  /* MODIFIERS */
  modifier onlyOfficial() {
    require(
      msg.sender == electionOfficial,
      "You are not authorized to take this action."
    );
    _;
  }

  modifier isRegisteredVoter() {
    require(
      voters[msg.sender].voterAddress != address(0),
      "Voter is not registered."
    );
    _;
  }

  modifier hasNotVoted() {
    require(
      voters[msg.sender].voted == false,
      "Voter has already voted."
    );
    _;
  }
  modifier correctVotingFormat(bool[] memory choices) {
    require(
      choices.length == proposals.length,
      "Incorrect format. Please ensure all proposals have been voted on."
    );
    _;
  }

  /* FUNCTIONS */
  //CONSTRUCTOR
  constructor(uint256 _numOfProposals) public {
    electionOfficial = msg.sender;

    proposals.length = _numOfProposals;
    winningProposals.length = _numOfProposals;

    for (uint256 i = 0; i < _numOfProposals; i++) {
      proposals[i].yesCount = 0;
      proposals[i].noCount = 0;
      proposals[i].totalVotes = 0;
    }
  }

  //ELECTION SETUP FUNCTIONS
  function register(address registeringVoter) public onlyOfficial {
    //Check if the voter is already registered based on their address
    if (voters[registeringVoter].voterAddress != address(0))
      revert("Voter is already registered.");

    voters[registeringVoter].voterAddress = registeringVoter;
    voters[registeringVoter].voted = false;
    voters[registeringVoter].choices.length = proposals
      .length;
    totalRegisteredVoters++;
    emit Registered(registeringVoter);
  }

  //VOTING FUNCTIONS
  function vote (bool[] memory choices)
    public
    isRegisteredVoter
    hasNotVoted
    correctVotingFormat(choices)
  {
    voters[msg.sender].choices = choices;

    for (uint256 index = 0; index < choices.length; index++) {
      if (choices[index] == false) {
        proposals[index].noCount++;
      } else if (choices[index] == true) {
        proposals[index].yesCount++;
      }
    }
    voters[msg.sender].voted = true;
    emit VoteCast(msg.sender);
  }

  function countProposals() public {
    for (uint256 index = 0; index < proposals.length; index++) {
      proposals[index].totalVotes =
        proposals[index].yesCount +
        proposals[index].noCount;
      if (
        proposals[index].yesCount > proposals[index].noCount
      ) {
        winningProposals[index] = true;
      } else {
        winningProposals[index] = false;
      }
      emit VotesCounted(
        proposals[index].totalVotes,
        proposals[index].yesCount,
        proposals[index].noCount
      );
    }
  }

  //AUDITING FUNCTIONS
  function getElectionOfficial() public view returns (address) {
    return electionOfficial;
  }

  function countRegisteredVoters() public view returns (uint256) {
    return totalRegisteredVoters;
  }

  
  function getTotalProposals() public view returns (uint256) {
    uint256 count = proposals.length;
    return count;
  }

  function getChoices(address voter)
    public
    view
    returns (bool[] memory)
  {
    if (msg.sender != voter)
      revert("You are not authorized to view this information.");
    return voters[voter].choices;
  }

  function getWinningProposals() public view returns (bool[] memory) {
    return winningProposals;
  }

  function getProposalCount(uint256 proposalNumber)
    public
    view
    returns (uint256[2] memory totalCounts)
  {
    totalCounts[0] = proposals[proposalNumber].noCount;
    totalCounts[1] = proposals[proposalNumber].yesCount;

    return totalCounts;
  }
}
