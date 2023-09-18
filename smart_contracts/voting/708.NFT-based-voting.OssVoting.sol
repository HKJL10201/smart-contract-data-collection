// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract PolimiVoting is AccessControl, Ownable {

    mapping(address => uint256) public votesReceived;
    bool public isVotingOpen;
    uint256 public voteCount;
    mapping(uint => address) public recipients;
    uint public recipientCount;
    mapping (address => bool) public hasVoted;
    address public PolimiNFTContractAddr;
    bytes32 public constant CLAIM_WINNER_ROLE = keccak256("CLAIM_WINNER_ROLE");


    constructor (address _recipient1, address _recipient2, address _recipient3, address _recipient4) {
        
        PolimiNFTContractAddr = 0x84C2444A52d2bcec9922f46F87BF0175BDe4c298; 
        recipients[0] = _recipient1;
        recipients[1] = _recipient2;
        recipients[2] = _recipient3;
        recipients[3] = _recipient4;
        recipientCount = 4;
        for (uint i = 0; i < recipientCount; i++) {
            for (uint j = i+1; j < recipientCount; j++) {
                require(recipients[i] != recipients[j], "4 different addresses are requested");
            }
        }  
        
    }
    
    event VotingClosed(string message);
    function changeVotingState() external onlyOwner {
        isVotingOpen = !isVotingOpen;
        if (!isVotingOpen) {
            address winner = findWinner();
            if (winner != address(0)) {
                _grantRole(CLAIM_WINNER_ROLE, winner);
                emit VotingClosed("Voting has ended. The winner address can now withdraw the funds");
            }            
        }
    }
 
    
    function tokenIdOwner(uint256 _tokenId) internal view virtual returns (address) {
            ERC721 nftContract = ERC721(PolimiNFTContractAddr);
            address owner = nftContract.ownerOf(_tokenId);
            return owner;
    }


    event VoteReceived(address voter, address recipient);
    function voteFor(uint _recipientId, uint256 _tokenId) external {   
        require(_recipientId < recipientCount, "This address is not in the contract");    
        require(recipients[_recipientId] != address(0), "This address cannot be voted on");
        require(isVotingOpen, "Voting is currently closed");
        address tokenOwner = tokenIdOwner(_tokenId);
        require(tokenOwner == msg.sender, "You're not the NFT owner that gives the right to vote. Check your token id");
        require(!hasVoted[msg.sender], "you already voted");
        hasVoted[msg.sender] = true;
        votesReceived[recipients[_recipientId]] += 1;
        voteCount += 1;
        emit VoteReceived(msg.sender, recipients[_recipientId]);   
    }

    function fundThisContract () external payable{}

    function claimFunds() public payable onlyRole(CLAIM_WINNER_ROLE) {
        require(address(this).balance > 0, "No funds available");
        (bool myTransfer,) = msg.sender.call{value: address(this).balance}("");
        require(myTransfer, "Failed transfer");
    }

    function findWinner() internal view returns (address) {
    uint256 maxVotes = 0;
    address winner = address(0);
        for (uint i = 0; i < recipientCount; i++) {
            if (votesReceived[recipients[i]] > maxVotes) {
                maxVotes = votesReceived[recipients[i]];
                winner = recipients[i];
            }
        }
    return winner;
    }

}