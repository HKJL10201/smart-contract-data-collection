pragma solidity >=0.4.22 <0.7.0;

import "./Authorizable.sol";

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
}

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot is Authorizable {
   ERC20Interface tokenContract;

    struct Voter {
        address voterAddress;
        uint weight; // weight is accumulated by token balance
        bool voted;  // if true, that person already voted
        uint decision;   // yes or no (1 or 0)
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        string title;
        string description;    
        uint yesVoteCount; // number of accumulated votes saying yes
        uint noVoteCount; // number of accumulated votes saying no

        uint dateProposed;
        uint expirationDate;
    }

    Proposal[] private proposals;

    mapping(uint => mapping(address => Voter)) private voters;

    mapping(uint => Voter[]) totalVoters;

    uint currentVoteBatch;


    constructor() public {
    }

    function setERC20ContractAddress(address _address) external onlyAuthorized {
      tokenContract = ERC20Interface(_address);
    }


    function addProposal(string memory _title, string memory _description) public onlyAuthorized {

        proposals.push(Proposal({
            title: _title,
            description: _description,
            yesVoteCount: 0,
            noVoteCount: 0,
            dateProposed: now,
            expirationDate: now + 30 days
        }));

        currentVoteBatch = proposals.length - 1;
    }

    function editProposal(uint voteBatch, string memory _title, string memory _description) public onlyAuthorized {
        
        require(proposals.length > voteBatch, "Proposal has not happened yet");

        proposals[voteBatch].title = _title;
        proposals[voteBatch].description = _description;        
        proposals[voteBatch].yesVoteCount = 0;
        proposals[voteBatch].noVoteCount = 0;
        proposals[voteBatch].dateProposed = now;
        proposals[voteBatch].expirationDate = now + 30 days;

        for(uint i = 0; i<totalVoters[voteBatch].length; i++) {
            totalVoters[voteBatch][i].voted = false;
            totalVoters[voteBatch][i].decision = 0;
        }


    }

    function vote(uint voteBatch, uint yesNo) public {
        Voter storage sender = voters[voteBatch][msg.sender];

        uint voteWeight = tokenContract.balanceOf(msg.sender);

        require(voteWeight != 0, "Has no tokens, and no right to vote");
        require(!sender.voted, "Already voted.");
        require(proposals[voteBatch].expirationDate >= now, "Proposal time to vote expired");
        require(proposals.length > voteBatch, "Proposal has not happened yet");


        sender.weight = voteWeight;
        sender.voted = true;
        sender.decision = yesNo;
        sender.voterAddress = msg.sender;

        totalVoters[voteBatch].push(sender);


        if(yesNo == 0){
            proposals[voteBatch].noVoteCount += sender.weight;            
        }
        else {
            proposals[voteBatch].yesVoteCount += sender.weight;                        
        }

    }
    
    function getLatestVoteBatch() public view returns(int){
        uint voteWeight = tokenContract.balanceOf(msg.sender);

        require(voteWeight != 0, "Has no tokens, and no right to vote");

        return int(proposals.length) - 1;
    }
    
    function getLatestProposal() public view returns(string memory title, string memory description, uint yesCount, uint noCount, uint proposed, uint expiration){
        uint voteWeight = tokenContract.balanceOf(msg.sender);

        require(voteWeight != 0, "Has no tokens, and no right to vote");
        require(proposals.length != 0, "No proposals made yet");
        
        title = proposals[proposals.length -1].title;
        description = proposals[proposals.length -1].description;
        yesCount = proposals[proposals.length -1].yesVoteCount;
        noCount = proposals[proposals.length -1].noVoteCount;
        proposed = proposals[proposals.length -1].dateProposed;
        expiration = proposals[proposals.length -1].expirationDate;
    }
    
    function getProposal(uint voteBatch) public view returns(string memory title, string memory description, uint yesCount, uint noCount, uint proposed, uint expiration){
        uint voteWeight = tokenContract.balanceOf(msg.sender);

        require(voteWeight != 0, "Has no tokens, and no right to vote");
        require(proposals.length > voteBatch, "Vote batch has not happened");
        
        title = proposals[voteBatch].title;
        description = proposals[voteBatch].description;        
        yesCount = proposals[voteBatch].yesVoteCount;
        noCount = proposals[voteBatch].noVoteCount;
        proposed = proposals[voteBatch].dateProposed;
        expiration = proposals[voteBatch].expirationDate;

    }

    function getVoters(uint voteBatch) public view 
    returns(address[] memory addresses, 
            uint[] memory weights, 
            bool[] memory voted, 
            uint[] memory decisions){
        uint voteWeight = tokenContract.balanceOf(msg.sender);

        require(voteWeight != 0, "Has no tokens, and no right to vote");

        addresses = new address[](totalVoters[voteBatch].length);
        weights = new uint[](totalVoters[voteBatch].length);
        voted = new bool[](totalVoters[voteBatch].length);
        decisions = new uint[](totalVoters[voteBatch].length);
        
        for(uint i = 0; i<totalVoters[voteBatch].length; i++) {
            addresses[i] = totalVoters[voteBatch][i].voterAddress;
            weights[i] = totalVoters[voteBatch][i].weight;
            voted[i] = totalVoters[voteBatch][i].voted;
            decisions[i] = totalVoters[voteBatch][i].decision;
        }
    }

    function getVoter(uint voteBatch) public view 
    returns(address voterAddress, 
            uint  weight, 
            bool  voted, 
            uint  decision){
        uint voteWeight = tokenContract.balanceOf(msg.sender);

        require(voteWeight != 0, "Has no tokens, and no right to vote");

        Voter memory sender = voters[voteBatch][msg.sender];

        voterAddress = sender.voterAddress;
        weight = sender.weight;
        voted = sender.voted;
        decision = sender.decision;
    }

}
