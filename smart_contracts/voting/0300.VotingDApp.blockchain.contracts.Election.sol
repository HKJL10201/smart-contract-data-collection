// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "../contracts/ERC20ElectionToken.sol";
import "../contracts/ERC721ElectionNFT.sol";


contract Election {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        string description;
    }

    mapping(uint => Candidate) public candidates;
    uint public candidatesCount;
    uint public electionStarts = 1658598886192; // 2022-07-23
    uint public electionEnds = 1659351900000; // 2022-08-01
    uint public votingTime = 1 * 60; // 1 minute
    // address tokenOwner;
    ERC20ElectionToken public erc20;
    ERC721ElectionNFT public erc721;

    event votedEvent (
        uint indexed _candidateId
    );

    event createdCandidateEvent (
        uint indexed candidateId,
        string indexed candidateName,
        uint indexed candidateVoteCount
    );

    constructor (ERC20ElectionToken erc20Address, ERC721ElectionNFT erc721Adress) {
        addCandidate("Yovel", "Young and desired to change the world");
        addCandidate("Idan", "Calculated and effects all aspects");
        // tokenOwner = msg.sender;
        erc20 = erc20Address;
        erc721 = erc721Adress;
    }

    function addCandidate (string memory _name, string memory description) public {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, description);
        emit createdCandidateEvent(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        require(erc721.balanceOf(msg.sender) < 1);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        require((block.timestamp * 1000) >= electionStarts && (block.timestamp * 1000) <= electionEnds);

        erc721.mint(msg.sender);
        candidates[_candidateId].voteCount ++;
        erc20.transfer(msg.sender, 10);

        emit votedEvent(_candidateId);
    }
}