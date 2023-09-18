pragma solidity ^0.4.17;

/*
    Contract CampaignFactory to create new campaigns and
    store addresses of the created campaigns
*/
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

/*
    Contract Campaign to provide the actual functionality
    to manage the complete election campaign from start to end
*/
contract Campaign {
    // voter model
    struct Voter {
        uint uid;   // unique id
        string fullName;
        string location;
        bool voted;
        uint cid;
    }
    
    // candidate model
    struct Candidate {
        uint uid;   // unique id
        string fullName;
        string location;
        uint votes;
    }
    
    address public manager; // election manager private key address
    string public name;     // campaign name

    Voter[] public voters;  // array of voters
    uint[] public vids;     // array of voter ids for lookup

    Candidate[] public candidates;  // array of candidates
    uint[] public cids;             // array of candidate ids for lookup

    uint public totalVotes;         // total votes polled
    bool public complete;           // campaign status

    uint public winner;             // winner uid
    
    mapping(uint => uint) public voterIndex;
    mapping(uint => uint) public candidateIndex;
    
    // create campaign function
    function Campaign(string campaignName, address sender) public {
        manager = sender;
        name = campaignName;
    }
    
    // register a new voter function
    function registerVoter(uint uid, string fullName, string location) public {
        Voter memory newVoter = Voter({
            uid: uid,
            fullName: fullName,
            location: location,
            voted: false,
            cid: 0
        });
        
        voters.push(newVoter);
        vids.push(uid);
        voterIndex[uid] = vids.length-1;
    }
    
    // register a new candidate function
    function registerCandidate(uint uid, string fullName, string location) public {
        Candidate memory newCandidate = Candidate({
            uid: uid,
            fullName: fullName,
            location: location,
            votes: 0
        });
        
        candidates.push(newCandidate);
        cids.push(uid);
        candidateIndex[uid] = cids.length-1;
    }

    // poll vote function    
    function pollVote(uint vid, uint cid) public {
        Voter storage voter = voters[voterIndex[vid]];
        //check if user already voted
        require(!voter.voted);
        // else poll vote
        voter.voted = true;
        voter.cid = cid;

        // increase candidate vote count
        Candidate storage candidate = candidates[candidateIndex[cid]];
        candidate.votes++;
        
        // increase total vote count
        totalVotes++;
    }
    
    // declare the campaign result
    function declareResult() public restricted {
        require(msg.sender == manager);
        require(!complete);
        // close the poll
        complete = true;
        
        uint max = 0;
        for (uint i=0; i<candidates.length; i++) {
            if (candidates[i].votes > max) {
                max = candidates[i].votes;
                winner = candidates[i].uid;
            }
        }
    }
    
    // get result summary
    function getResult() public view returns(
        uint, uint, uint
        ) {
        return (
            totalVotes, 
            candidates[candidateIndex[winner]].votes, 
            winner
        );    
    }
    
    // get campaign summary
    function getSummary() public view returns(
        uint, uint, uint
        ) {
        return (
            voters.length, 
            candidates.length, 
            totalVotes
        );    
    }

    // get total registered voters count
    function getVotersCount() public view returns(uint) {
        return voters.length;
    }

    // get total registered candidate count
    function getCandidatesCount() public view returns(uint) {
        return candidates.length;
    }

    // get unique ids of all registered voters
    function getVoterIds() public view returns(uint[]) {
        return vids;
    }

    // get unique ids of all registered candidates
    function getCandidateIds() public view returns(uint[]) {
        return cids;
    }
    
    // modifier to restrict method calling only by the campaign manager
    modifier restricted {
        require(msg.sender == manager);
        _;
    }
}