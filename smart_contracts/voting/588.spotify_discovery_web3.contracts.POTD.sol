// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract POTD {
    uint256 totalPlaylists;
    uint256 totalVotes;
    uint256 private seed;

    event NewPlaylist(address indexed from, uint256 timestamp, string url);
    event NewVote(address indexed from, address playlistr, uint256 timestamp, string url);

    struct Playlist {
        address playlistr; // The address of the user who playlistd.
        string url; // The message the user sent.
        uint256 timestamp; // The timestamp when the user playlistd.
    }

    Playlist[] playlists;

    struct Vote {
        address voter;
        address playlistr; // The address of the user who playlistd.
        string url; // The message the user sent.
        uint256 timestamp; // The timestamp when the user playlistd.
    }

    Vote[] votes;

    mapping(address => uint256) public lastProposalAt;
    mapping(address => uint256) public lastVoteAt;

    constructor() payable {
        console.log("I AM SMART CONTRACT.");
        seed = (block.timestamp + block.difficulty) % 100;
    }

    function vote(address _playlistr, string memory _url, uint256 _proposalTimestamp) public {
        require(
            lastVoteAt[msg.sender] + 1 days < block.timestamp,
            "Wait 1 day"
        );
        lastVoteAt[msg.sender] = block.timestamp;

        totalVotes += 1;
        votes.push(Vote(msg.sender, _playlistr, _url, _proposalTimestamp));
        emit NewVote(msg.sender, _playlistr, _proposalTimestamp, _url);
    }

    function proposal(string memory _url) public {
        require(
            lastProposalAt[msg.sender] + 1 days < block.timestamp,
            "Wait 1 day"
        );
        lastProposalAt[msg.sender] = block.timestamp;
        
        totalPlaylists += 1;
        console.log("%s playlistd w/ message %s", msg.sender, _url);
        playlists.push(Playlist(msg.sender, _url, block.timestamp));
        seed = (block.difficulty + block.timestamp + seed) % 100;
        if (seed <= 50) {
            uint256 prizeAmount = 0.00001 ether;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        }
        emit NewPlaylist(msg.sender, block.timestamp, _url);
    }

    function getAllPlaylists() public view returns (Playlist[] memory) {
        return playlists;
    }

    function getAllVotes() public view returns (Vote[] memory) {
        return votes;
    }

    function getTodayPlaylists() public view returns (Playlist[] memory) {
        uint256 resultCount;

        for (uint256 i = 0; i < playlists.length; i++) {
            if (
                ((block.timestamp - playlists[i].timestamp) / 60 / 60 / 24) == 0
            ) {
                resultCount++;
            }
        }
        
        Playlist[] memory result = new Playlist[](resultCount);
        uint256 j;

        for (uint256 i = 0; i < playlists.length; i++) {
            if (
                ((block.timestamp - playlists[i].timestamp) / 60 / 60 / 24) == 0
            ) {
                result[j] = playlists[i];
                j++;
            }
        }
        return result;
    }

    function getTodayVotes() public view returns (Vote[] memory) {
        uint256 resultCount;

        for (uint256 i = 0; i < votes.length; i++) {
            if (
                ((block.timestamp - votes[i].timestamp) / 60 / 60 / 24) == 0
            ) {
                resultCount++;
            }
        }
        
        Vote[] memory result = new Vote[](resultCount);
        uint256 j;

        for (uint256 i = 0; i < votes.length; i++) {
            if (
                ((block.timestamp - votes[i].timestamp) / 60 / 60 / 24) == 0
            ) {
                result[j] = votes[i];
                j++;
            }
        }
        return result;
    }

    function getTotalPlaylists() public view returns (uint256) {
        console.log("We have %d total playlists referenced!", totalPlaylists);
        return totalPlaylists;
    }
}
