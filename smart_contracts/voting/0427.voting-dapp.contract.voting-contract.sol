pragma solidity ^0.4.16;

contract VotingContract {
    address owner;
    
    uint public startTimestamp = 1509872400; // Change to offical start time
    uint public endTimestamp = 1589901200; // Change to official end time
    
    // Zweitstimme Landesliste 1
    mapping (address => uint8) public zs1ValidVoters;
    mapping (bytes => bool) zs1CoinCommitments;
    mapping (bytes32 => bool) zs1HashedVotes;
    mapping (bytes => bool) zs1SpendSerialNumbers;
    uint8[] public zs1RevealedVotes;
    
    // Erststimme Wahlkreis 1
    mapping (address => uint8) public es1ValidVoters;
    mapping (bytes => bool) es1CoinCommitments;
    mapping (bytes32 => bool) es1HashedVotes;
    mapping (bytes => bool) es1SpendSerialNumbers;
    uint8[] public es1RevealedVotes;
    

    function VotingContract() public {
        owner = msg.sender;
    }
    
    /**
    * Called from state for sending votes initially to voter (approve him to vote)
    */
    function validateVoter(address voter, uint16 constituency, uint8 countryList) public {
        require(msg.sender == owner);
        if (constituency == 1) {
            es1ValidVoters[voter] = 1;
        }
        if (countryList == 1) {
            zs1ValidVoters[voter] = 1;
        }
    }
    
    /**
     * Called from the voter
     */
    function mint(bytes coinCommitment, uint16 voteType) public returns (bool) {
        require(block.timestamp >= startTimestamp);
        require(block.timestamp <= endTimestamp);
        
        if (voteType == 1) {
            require(es1ValidVoters[msg.sender] == 1);
            es1CoinCommitments[coinCommitment] = true;
            es1ValidVoters[msg.sender] = 2; // Update status
        }
        if (voteType == 300) {
            require(zs1ValidVoters[msg.sender] == 1);
            zs1CoinCommitments[coinCommitment] = true;
            zs1ValidVoters[msg.sender] = 2; // Update status
        }
        
        return true;
    }
    
    /**
     * Vote function, called from am new address
     */ 
    function spend(bytes serialNumber, bytes32 hashedVote, uint16 voteType) public returns (bool) {
        require(block.timestamp >= startTimestamp);
        require(block.timestamp <= endTimestamp);
        
        if (voteType == 1) {
            // TODO zkSNARK: Check if serialNumber has coinCommitment in wk1CoinCommitments
            if (es1SpendSerialNumbers[serialNumber] != true) {
                es1HashedVotes[hashedVote] = true;
                es1SpendSerialNumbers[serialNumber] = true;
            }
        }
        if (voteType == 300) {
            // TODO zkSNARK: Check if serialNumber has coinCommitment in zsCoinCommitments
            if (zs1SpendSerialNumbers[serialNumber] != true) {
                zs1HashedVotes[hashedVote] = true;
                zs1SpendSerialNumbers[serialNumber] = true;
            }
        }
        
        return true;
    }
    
    /**
     * Reavels the vote
     */
    function reveal(uint8 vote, bytes32 salt, uint16 voteType) public returns (bool) {
        require(block.timestamp >= endTimestamp);
        
        bytes32 hashedVote = shaVote(msg.sender, vote, salt);
        
        if (voteType == 1) {
            if (es1HashedVotes[hashedVote] == true) {
                es1RevealedVotes.push(vote);
                es1HashedVotes[hashedVote] = false;
            }
        }
        if (voteType == 300) {
            if (zs1HashedVotes[hashedVote] == true) {
                zs1RevealedVotes.push(vote);
                zs1HashedVotes[hashedVote] = false;
            }
        }
        
        return true;
    }
    
    function shaVote(address voter, uint vote, bytes32 salt) constant returns (bytes32 sealedVote) {
        return keccak256(voter, vote, salt);
    }
}