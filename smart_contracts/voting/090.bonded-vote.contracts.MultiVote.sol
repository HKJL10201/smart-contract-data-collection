pragma solidity >=0.5.0 <0.7.0;

contract BondManager {
  function accounts(address) public view returns (uint256, uint256);
  function processBond(address, uint256, address) public;
}

contract MultiVote {
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

  function processVote(uint256[] memory optionIds, uint256[] memory votes) public {
    assert(optionIds.length == votes.length); // ensure arguments are valid
    assert(block.number <= deadline); // prevent voting after the deadline
    assert(records[msg.sender] == uint256(0)); // account must not have already voted

    bondManager.processBond(msg.sender, deadline, asset); // try to bond the account that is voting
    (uint256 allotted, ) = bondManager.accounts(msg.sender); // get account's current bonded balance

    uint256 leadingId = leading; // save a local leading id to be used in memory
    uint256 total = uint256(0);
    for (uint256 i = 0; i < optionIds.length; i++) {
      assert(optionIds[i] < options); // prevent the vote from being cast on an unavailable option

      if (i > 0) {
        assert(optionIds[i] > optionIds[i - 1]); // optionIds must be in order, to prevent duplicates
      }

      uint256 newTotal = total + votes[i];
      assert(newTotal > total); // prevent overflow
      total = newTotal;

      tallies[optionIds[i]] += votes[i]; // add support to option (no need for safe math since total must later be less than alloted, which is in real wei)
      records[msg.sender] += votes[i]; // record that account has voted on this proposal, and how much, (not the direction)

      if (tallies[optionIds[i]] >= tallies[leadingId]) {
        leadingId = optionIds[i]; // update the local leading option if it has been overtaken
      }

      emit VoteCounted(msg.sender, optionIds[i], votes[i]);
    }

    assert(total <= allotted); // prevent voting more than was bonded

    leading = leadingId; // save local leading id to storage
  }
}
