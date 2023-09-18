pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;
    
    function createCampaign(string campaignName) public {
        address newCampaign = new Campaign(campaignName, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns(address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Voter {
        uint aadhaar;
        string fullName;
        string location;
        bool voted;
        uint candidateIndex;
    }
    
    struct Candidate {
        uint aadhaar;
        string fullName;
        string location;
        uint votes;
    }
    
    address public manager;
    string public name;
    Voter[] public voters;
    uint[] public vids;
    Candidate[] public candidates;
    uint[] public cids;
    uint public totalVotes;
    bool public complete;
    uint public winner;
    
    mapping(uint => uint) public voterIndex;
    mapping(uint => string) public candidateIndex;
    
    function Campaign(string campaignName, address sender) public {
        manager = sender;
        name = campaignName;
    }
    
    function registerVoter(uint aadhaar, string fullName, string location) public {
        Voter memory newVoter = Voter({
            aadhaar: aadhaar,
            fullName: fullName,
            location: location,
            voted: false,
            candidateIndex: 0
        });
        
        voters.push(newVoter);
        vids.push(aadhaar);
    }
    
    function registerCandidate(uint aadhaar, string fullName, string location) public {
        Candidate memory newCandidate = Candidate({
            aadhaar: aadhaar,
            fullName: fullName,
            location: location,
            votes: 0
        });
        
        candidates.push(newCandidate);
        cids.push(aadhaar);
        candidateIndex[aadhaar] = fullName;
    }
    
    function pollVote(uint userAadhaar, uint cid) public {
        // require(!userVotes(userAadhaar));
        
        // get voter details & update vote details
        Voter storage voter = voters[voterIndex[userAadhaar]];
        
        require(!voter.voted);
        
        // update user vote flag
        voter.voted = true;
        voter.candidateIndex = cid;
        
        // update user vote flag
        // userVotes[userAadhaar] = true;
        
        // increase candidate vote count
        candidates[cid].votes++;
        
        // increase total vote count
        totalVotes++;
    }
    
    function declareResult() public restricted {
        // close the poll
        complete = true;
        
        uint max = 0;
        for (uint i=0; i<candidates.length; i++) {
            if (candidates[i].votes > max) {
                max = candidates[i].votes;
                winner = candidates[i].aadhaar;
            }
        }
    }
    
    function getResult() public view returns(
        uint, uint, uint
        ) {
        return (
            totalVotes, 
            candidates[winner].votes, 
            winner
        );    
    }
    
    function getSummary() public view returns(
        uint, uint, uint
        ) {
        return (
            voters.length, 
            candidates.length, 
            totalVotes
        );    
    }

    function getVotersCount() public view returns(uint) {
        return voters.length;
    }

    function getCandidatesCount() public view returns(uint) {
        return candidates.length;
    }

    function getVoterIds() public view returns(uint[]) {
        return vids;
    }

    function getCandidateIds() public view returns(uint[]) {
        return cids;
    }
    
    modifier restricted {
        require(msg.sender == manager);
        _;
    }
}