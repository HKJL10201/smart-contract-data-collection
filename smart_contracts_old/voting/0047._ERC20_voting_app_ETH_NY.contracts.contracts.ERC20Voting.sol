pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./MerkleProof.sol";

/**
 * @title ERC20 voting smart contract.
 * @author https://peppersec.com
 * @notice This smart contract implements voting based on ERC20 token. One token equals one vote.
 * The voting goes up to date chosen by a voting creator. During the voting time, each token holder
 * can cast for one of three options: "No", "Yes". Read more
 * about options at
 * @dev Voting creator deploys the contract Merkle Tree root and expiration date.
 * And then, each token holder which included in the Merkle Tree can vote via `vote` method.
 */
contract ERC20Voting {
    using SafeMath for uint256;

    /// @dev The voting offers two options only
    enum VotingOption { NotVoted, No, Yes }

    /// @dev Stores votes (token amount) that holders has votted so far.
    struct VotingResult {
        uint256 no;
        uint256 yes;
    }
    VotingResult public votingResult;

    /// @dev SkaleFileLink hash of the published Merkle Tree that contains token holders.
    string public skaleFileLink;

    /// @dev Topic question of a ballot
    string public ballotQuestion;

    /// @dev Stores vote of each holder.
    mapping (address => VotingOption) public votes;

    /// @dev Date up to which votes are accepted (timestamp).
    uint256 public expirationDate;

    /// @dev Merkle Tree root loaded by the voting creator, which is base for voters' proofs.
    bytes32 public merkleTreeRoot;

    /// @dev The event is fired when a holder makes a choice.
    event NewVote(address who, VotingOption vote, uint256 amount);

    /**
    * @dev ERC20Voting contract constructor.
    * @param _merkleTreeRoot Merkle Tree root of token holders.
    * @param _skaleFileLink SkaleFileLink hash where the Merkle Tree is stored.
    * @param _expirationDate Date up to which votes are accepted (timestamp).
    */
    constructor(
        bytes32 _merkleTreeRoot,
        string memory _skaleFileLink,
        uint256 _expirationDate,
        string memory _ballotQuestion
    ) public {
        require(_expirationDate > block.timestamp, "wrong expiration date");
        ballotQuestion = _ballotQuestion;
        merkleTreeRoot = _merkleTreeRoot;
        skaleFileLink = _skaleFileLink;
        expirationDate = _expirationDate;
    }

    /**
    * @dev ERC20Voting vote function.
    * @param _vote Holder's vote decision.
    * @param _amount Holder's voting power (token amount).
    * @param _proof Array of hashes that proofs that a sender is in the Merkle Tree.
    */
    function vote(VotingOption _vote, uint256 _amount, bytes32[] calldata _proof) external {
        require(canVote(msg.sender), "already voted");
        require(isVotingOpen(), "voting finished");
        require(_vote > VotingOption.NotVoted && _vote <= VotingOption.Yes, "invalid vote option");
        bytes32 _leaf = keccak256(abi.encodePacked(keccak256(abi.encode(msg.sender, _amount))));
        require(verify(_proof, merkleTreeRoot, _leaf), "the proof is wrong");

        votes[msg.sender] = _vote;
        if (_vote == VotingOption.No) {
            votingResult.no = votingResult.no.add(_amount);
        } else {
            votingResult.yes = votingResult.yes.add(_amount);
        }

        emit NewVote(msg.sender, _vote, _amount);
    }

    /**
    * @dev Returns current results of the voting. All the percents have 2 decimal places.
    * e.g. value 1337 has to be interpreted as 13.37%
    * @param _expectedVotingAmount Total amount of tokens of all the holders.
    * @return noPercent Percent of votes casted for "No" option.
    * @return noVotes Amount of tokens casted for "No" option.
    * @return yesPercent Percent of votes casted for "Yes" option.
    * @return yesVotes Amount of tokens casted for "Yes" option.
    * @return totalVoted Total amount of tokens voted.
    * @return turnoutPercent Percent of votes casted so far.
    */
    function votingPercentages(uint256 _expectedVotingAmount) external view returns(
        uint256 noPercent,
        uint256 noVotes,
        uint256 yesPercent,
        uint256 yesVotes,
        uint256 totalVoted,
        uint256 turnoutPercent
    ) {
        noVotes = votingResult.no;
        yesVotes = votingResult.yes;
        totalVoted = noVotes.add(yesVotes);

        uint256 oneHundredPercent = 10000;
        noPercent = votingResult.no.mul(oneHundredPercent).div(totalVoted);
        yesPercent = oneHundredPercent.sub(noPercent);

        turnoutPercent = totalVoted.mul(oneHundredPercent).div(_expectedVotingAmount);
    }

    /**
    * @dev Returns true if the voting is open.
    * @return if the holders still can vote.
    */
    function isVotingOpen() public view returns(bool) {
        return block.timestamp <= expirationDate;
    }

    /**
    * @dev Returns true if the holder has not voted yet. Notice, it does not check
    the `_who` in the Merkle Tree.
    * @param _who Holder address to check.
    * @return if the holder can vote.
    */
    function canVote(address _who) public view returns(bool) {
        return votes[_who] == VotingOption.NotVoted;
    }

    /**
    * @dev Allows to verify Merkle Tree proof.
    * @param _proof Array of hashes that proofs that the `_leaf` is in the Merkle Tree.
    * @param _root Merkle Tree root.
    * @param _leaf Bottom element of the Merkle Tree.
    * @return verification result (true of false).
    */
    function verify(bytes32[] memory _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }
}
