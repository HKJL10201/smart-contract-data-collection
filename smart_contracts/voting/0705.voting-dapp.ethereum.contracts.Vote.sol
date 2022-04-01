pragma solidity ^0.4.21;

// Using this contract to deploy many ballot as you want
contract BallotFactory {

    uint public costPerBallot;  // you must pay "costPerBallot" ether to create new ballot
    address public owner;   
    address[] public deployedBallots;

    constructor (uint _costPerBallot) public payable {
        owner = msg.sender;
        costPerBallot = _costPerBallot * 1 ether;
    }

    function createBallot (
        string _description, 
        uint[] candidateIds, 
        bytes32[] candidateNames, 
        bytes32[] imgHashHead,
        bytes32[] imgHashTail, 
        uint tokens, 
        uint pricePerToken, 
        uint _voteTime
        )
    public payable returns (address) {
        require(msg.value >= costPerBallot, "You do not give enough money to create one ballot");

        address newBallot = new Ballot(_description, 
        candidateIds, 
        candidateNames, 
        imgHashHead,
        imgHashTail, 
        tokens, 
        pricePerToken, 
        _voteTime, 
        msg.sender);

        deployedBallots.push(newBallot);

        return newBallot;
    }

    function getDeployedBallots() public view returns (address[]) {
        return deployedBallots;
    }

    function getBalance() public view returns (uint) {
        return this.balance;
    }

    function withdraw () public {
        require(msg.sender == owner, "only owner can do this");
        owner.transfer(this.balance);
    }
}

contract Ballot {

    // This is a type for a single voter
    struct voter {
        uint tokensBought;    // The total no. of tokens this voter bought
        uint availableTokens;   // Tokens that voter can use to vote
        bool[] tokensUsedPerCandidate; // Array to keep track candidates this voter voted.
    }

    // This is a type for a single candidate
    struct candidate {
        uint id;
        bytes32 name;   // Short name (up to 32 bytes)
        bytes32 imgHashHead; // first half of image ipfs hash
        bytes32 imgHashTail; // second half of image ipfs hash
        uint voteCount; // Number of accumulated votes
    }

    address public owner; // creator of this ballot

    string public description;  // Description for this ballot
    candidate[] public candidateList; // List of candidates
    
    uint public totalTokens; // Total no. of tokens available for this election
    uint public balanceTokens; // Total no. of tokens still available for purchase
    uint public tokenPrice; // Price per token

    uint public startTime;
    uint public voteTime; // After this amount of second, ballot is close

    /// MAPPING
    mapping (address => voter) public voters;

    function voterDetails(address voter) public view returns(uint, uint, bool[]){
        return (voters[voter].tokensBought, voters[voter].availableTokens, voters[voter].tokensUsedPerCandidate);
    }

    /// MODIFIER
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can do this");
        _;
    }

    modifier availableTime(){
        require(now  < startTime + voteTime, "Voting time is over");
        _;
    }

    ///CONSTRUCTOR
    constructor (
        string _description, 
        uint[] candidateIds, 
        bytes32[] candidateNames,
        bytes32[] imgHashHead,
        bytes32[] imgHashTail,
        uint tokens, 
        uint pricePerToken, 
        uint _voteTime,
        address _owner)
    public payable {
        require(candidateNames.length == candidateIds.length, "Number of name must equals number of id");
        require(imgHashHead.length == candidateIds.length, "Number of images must equals number of id");
        require(imgHashTail.length == candidateIds.length, "Number of images must equals number of id");

        owner = _owner;
        description = _description;

        totalTokens = tokens;
        balanceTokens = tokens;
        tokenPrice = pricePerToken;
        startTime = now;
        voteTime = _voteTime;

        for(uint i = 0; i < candidateNames.length; i ++ ){
            candidateList.push(candidate({
                id: candidateIds[i],
                name: candidateNames[i],
                imgHashHead: imgHashHead[i],
                imgHashTail: imgHashTail[i],
                voteCount: 0
            }));
        }
    }


    /// MAIN FUNCTION
    // Voter must buy tokens to vote.
    // They can vote for many candidates as they want, 1 token per candidate.
    function buy() public payable  availableTime returns (uint) {
        uint tokensToBuy = msg.value / tokenPrice;
        //Can not buy more than balance tokens.
        require(tokensToBuy <= balanceTokens, "Available tokens is not enough for you");

        //update ballot tokens, voter tokens
        voters[msg.sender].tokensBought += tokensToBuy;
        voters[msg.sender].availableTokens += tokensToBuy;
        balanceTokens -= tokensToBuy;

        //For one candidate, maximum tokens a voter can vote is 1.
        //So, maximum tokens voter can buy is number of candidates. 
        //If there are 9 candidates, maximum tokens voter could buy is 9.
        require(voters[msg.sender].tokensBought <= candidateList.length, "You can not buy more tokens");
        
        //Initiate arrar tokensUsedPerCandidate
        if (voters[msg.sender].tokensUsedPerCandidate.length == 0){
            for(uint i = 0; i < candidateList.length; i++){
                voters[msg.sender].tokensUsedPerCandidate.push(false);
            }
        }

        return tokensToBuy;
    }

    // Vote for candidate with id "_id"
    function voteForCandidate(uint _id) public availableTime {

        // Using id to find index of candidate
        // Because we can not directly find candidate by id
        uint index = indexOfCandidate(_id);
        require (index != uint(-1), "this id is not valid");

        // Require this voter has enough tokens to cast the vote
        require (voters[msg.sender].availableTokens >= 1, "You do not have token.");
        
        // Require this voter was not vote for this candidate yet.
        require(voters[msg.sender].tokensUsedPerCandidate[index] == false, "You already vote for this candidate");
        
        // Update tokens of this voter
        voters[msg.sender].availableTokens -= 1;
        voters[msg.sender].tokensUsedPerCandidate[index] = true;

        // Update voteCount of candidate
        candidateList[index].voteCount += 1;
    }

    function tokensSold() public view returns (uint) {
        return totalTokens - balanceTokens;
    }

    function numberCandidates() public view returns (uint) {
        return candidateList.length;
    }

    function getBalance() public view returns (uint) {
        return this.balance;
    }

    // Ballot creation can withdraw money when ballot close
    function withdraw() public onlyOwner {
        require(now >= startTime + voteTime, "Voting time is not over");
        owner.transfer(this.balance);
    }

    /// HELPER FUNCTION
    // Get index of candidate by id
    function indexOfCandidate(uint _id) private view returns (uint) {
        for(uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i].id == _id) {
                return i;
            }
        }
        return uint(-1);
    }

    function isOpen() public view returns (bool) {
        return now < startTime + voteTime;
    }
 
}