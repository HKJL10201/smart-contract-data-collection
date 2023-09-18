pragma solidity >=0.5.0 <0.7.0;

contract BondManager {
  function accounts(address) public view returns (uint256, uint256);
  function processBond(address, uint256, address) public;
}

contract SimpleVote {
  event VoteCounted(address indexed account, uint256 indexed option, uint256 indexed amount);

  BondManager public bondManager;

  address public asset; // token contract of the underlying expected bond (address(0) for ETH)
  uint256 public deadline; // deadline to vote on this proposal
  bytes32 public descriptionDigest; // hash of some arbitray description for this proposal
  uint256 public leading; // the leading option for this proposal, kept up to date with each new vote cast
  uint256 public options; // number of options for this proposal

  mapping(uint256 => uint256) public tallies; // effieicntly holds the tallies for all options
  mapping(address => uint256) public records; // used to check if an account has already voted, (helpful public historical query)

  constructor(
    address _bondManager,
    uint256 _options,
    uint256 _deadline,
    bytes32 _descriptionDigest,
    address _asset
  ) public {
    assert(_options > uint256(0)); // the proposal must have at least 1 option
    assert(_deadline > block.number); // deadline must be at greater than current block
    bondManager = BondManager(_bondManager);
    asset = _asset;
    deadline = _deadline;
    descriptionDigest = _descriptionDigest;
    options = _options;
  }

  function processVote(uint256 optionId, uint256 amount) public {
    assert(block.number <= deadline); // prevent voting after the deadline
    assert(optionId < options); // prevent the vote from being cast on an unavailable option
    assert(records[msg.sender] == uint256(0)); // account must not have already voted

    bondManager.processBond(msg.sender, deadline, asset); // try to bond the account that is voting

    (uint256 allotted, ) = bondManager.accounts(msg.sender); // get account's current bonded balance
    assert(amount <= allotted); // prevent voting with more weight than bonded

    tallies[optionId] += amount; // add support to option (no need for safe math since alloted is in real wei)
    records[msg.sender] = amount; // record that account has voted on this proposal, and how much, (not the direction)

    if (tallies[optionId] >= tallies[leading]) {
      leading = optionId; // update the leading option if it has been overtaken
    }

    emit VoteCounted(msg.sender, optionId, amount);
  }
}
