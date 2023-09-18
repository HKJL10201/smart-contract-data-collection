// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./tokens/interface/IRewardToken.sol";
import "./tokens/interface/IVoteNFT.sol";

contract Election {
    //Election details will be stored in these variables
    string public name;
    string public description;

    //Structure of candidate standing in the election
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    //Storing candidates in a map
    mapping(uint256 => Candidate) public candidates;

    //Storing address of those voters who already voted
    mapping(address => bool) public voters;
    mapping(uint256 => address) public voterGet;

    //Number of candidates in standing in the election
    uint256 public candidatesCount = 0;

    //Number of voters that have voted in the election
    uint256 public voterCount = 0;

    // reward token interface
    IRewardToken public immutable token;
    uint256 public VOTE_ISSUANCE = 10 ether;

    // voter nft interface
    IVoteNFT public immutable nft;

    // election time length calculation variables
    uint256 public startDate;
    uint256 public ELECTION_LENGTH;

    Candidate public winner;

    //Setting of variables and data, during the creation of election contract
    constructor(
        address tokenAddress,
        address nftAddress,
        string[] memory _nda,
        string[] memory _candidates,
        uint256 electionLength
    ) {
        require(_candidates.length > 0, "There should be atleast 1 candidate.");
        name = _nda[0];
        description = _nda[1];
        for (uint256 i = 0; i < _candidates.length; i++) {
            addCandidate(_candidates[i]);
        }

        ELECTION_LENGTH = electionLength;

        // reward token interface setting with address
        token = IRewardToken(tokenAddress);

        // voter nft contract interface setting with address
        nft = IVoteNFT(nftAddress);

        startDate = block.timestamp;
    }

    //Private function to add a candidate
    function addCandidate(string memory _name) private {
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        candidatesCount++;
    }

    //Public vote function for voting a candidate
    function vote(uint256 _candidate) public {
        // Compares current time to revert if election has ended
        require(
            startDate + ELECTION_LENGTH > block.timestamp,
            "This election has ended!"
        );

        require(!voters[msg.sender], "Voter has already Voted!");
        require(
            _candidate < candidatesCount && _candidate >= 0,
            "Invalid candidate to Vote!"
        );

        // Checks if caller has voter nft
        require(
            nft.balanceOf(msg.sender) > 0,
            "Caller does not have voting right"
        );
        voters[msg.sender] = true;
        voterGet[voterCount] = msg.sender;
        voterCount++;
        candidates[_candidate].voteCount++;

        // minting VOTE_ISSUANCE reward tokens to voter
        token.mint(msg.sender, VOTE_ISSUANCE);
    }

    // public function to end the election
    function endElection() public returns (string memory) {
        require(
            startDate + ELECTION_LENGTH < block.timestamp,
            "Election time has not ran out!"
        );
        selectWinner();
        return winner.name;
    }

    // internal function that selects the winner using vote counts
    function selectWinner() internal {
        uint256 maxVotes = 0;
        Candidate memory maxWinner;
        for (uint256 i = 0; i < candidatesCount; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                maxWinner = candidates[i];
            }
        }
        winner = maxWinner;
    }
}
