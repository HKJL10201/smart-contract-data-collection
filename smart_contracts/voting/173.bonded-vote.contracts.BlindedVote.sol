pragma solidity >=0.5.0 <0.7.0;

contract BondManager {
  function accounts(address) public view returns (uint256, uint256);
  function processBond(address, uint256, address) public;
}

contract BlindedVote {
  event CommitmentMade(address indexed account, uint256 indexed maxAmount);
  event VoteCounted(address indexed account, uint256 indexed option, uint256 indexed amount);

  BondManager public bondManager;

  address public asset; // token contract of the underlying expected bond (address(0) for ETH)
  uint256 public commitmentDeadline; // deadline to commit a vote on this proposal
  bytes32 public descriptionDigest; // hash of some arbitray description for this proposal
  uint256 public leading; // the leading option for this proposal, kept up to date with each new vote cast
  uint256 public options; // number of options for this proposal
  uint256 public voteDeadline; // deadline to vote on this proposal

  mapping(address => bytes32) public commitments;
  mapping(address => uint256) public maxAmounts;
  mapping(uint256 => uint256) public tallies; // effieicntly holds the tallies for all options
  mapping(address => uint256) public records; // used to check if an account has already voted, (helpful public historical query)

  constructor(
    address _bondManager,
    uint256 _options,
    uint256 _commitmentDeadline,
    uint256 _voteDeadline,
    bytes32 _descriptionDigest,
    address _asset
  ) public {
    assert(_options > uint256(0)); // the proposal must have at least 1 option
    assert(_commitmentDeadline > block.number); // commitment deadline must greated than current block
    assert(_voteDeadline > _commitmentDeadline); // vote deadline must greated than commitment deadline
    bondManager = BondManager(_bondManager);
    asset = _asset;
    commitmentDeadline = _commitmentDeadline;
    descriptionDigest = _descriptionDigest;
    options = _options;
    voteDeadline = _voteDeadline;
  }

  function commit(bytes32 commitment) public {
    assert(block.number <= commitmentDeadline); // prevent committing after the commitment deadline
    assert(commitments[msg.sender] == bytes32(0)); // prevent re-committing

    bondManager.processBond(msg.sender, voteDeadline, asset); // try to bond the account that is voting
    (uint256 allotted, ) = bondManager.accounts(msg.sender); // get account's current bonded balance

    commitments[msg.sender] = commitment; // store the commitment to be verified against later
    maxAmounts[msg.sender] = allotted; // store the allotted amount to be verified against later

    emit CommitmentMade(msg.sender, allotted);
  }

  function vote(uint256 optionId, uint256 amount, bytes32 salt) public {
    assert(block.number <= voteDeadline); // prevent voting after the vote deadline
    assert(optionId < options); // prevent the vote from being cast on an unavailable option
    assert(records[msg.sender] == uint256(0)); // account must not have already voted
    assert(amount <= maxAmounts[msg.sender]); // prevent voting with more weight than committed max amount

    bytes32 commitment = sha256(abi.encodePacked(optionId, amount, salt)); // compute the commitment
    assert(commitments[msg.sender] == commitment); // verify against the stored commitment
    commitments[msg.sender] = bytes32(0); // delete the commitment to clear state

    tallies[optionId] += amount; // add support to option (no need for safe math since alloted is in real wei)
    records[msg.sender] = amount; // record that account has voted on this proposal, and how much, (not the direction)

    if (tallies[optionId] >= tallies[leading]) {
      leading = optionId; // update the leading option if it has been overtaken
    }

    emit VoteCounted(msg.sender, optionId, amount);
  }
}
