pragma solidity ^0.4.21;
// We have to specify what version of compiler this code will compile with

import "./Ownable.sol";


contract Voting is Ownable {

    // We use the struct datatype to store the voter information.
    struct Voter {
        address voterAddress; // The address of the voter
        uint tokensBought;    // The total no. of tokens this voter owns
        uint[] tokensUsedPerCandidate; // Array to keep track of votes per candidate.
        /* We have an array called candidateList initialized below.
        Every time this voter votes with his/her tokens, the value at that
        index is incremented. Example, if candidateList array declared
        below has ["Rama", "Nick", "Jose"] and this
        voter votes 10 tokens to Nick, the tokensUsedPerCandidate[1] 
        will be incremented by 10.
        */
    }

    /* mapping field below is equivalent to an associative array or hash.
    The key of the mapping is candidate name stored as type bytes32 and value is
    an unsigned integer to store the vote count
    */
    mapping (bytes32 => uint8) public votesReceived;
    mapping (address => Voter) public voterInfo;

    /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
    We will use an array of bytes32 instead to store the list of candidates
    */
    bytes32[] public candidateList;
    uint public totalTokens; // Total no. of tokens available for this election
    uint public balanceTokens; // Total no. of tokens still available for purchase
    uint public tokenPrice; // Price per token

    /* This is the constructor which will be called once when you
    deploy the contract to the blockchain. When we deploy the contract,
    we will pass an array of candidates who will be contesting in the election
    */
    function Voting(uint tokens, uint pricePerToken, bytes32[] candidateNames) public {
        candidateList = candidateNames;
        totalTokens = tokens;
        balanceTokens = tokens;
        tokenPrice = pricePerToken;
    }

    /* This function is used to purchase the tokens. Note the keyword 
    'payable' below. By just adding that one keyword to a function, 
    your contract can now accept Ether from anyone who calls this 
    function. Accepting money can not get any easier than this!
    */
    function buy() public payable returns (uint) {
        log2(
            bytes32(keccak256(msg.value)),
            bytes32(msg.sender),
            bytes32(keccak256(tokenPrice))
        );
        uint tokensToBuy = msg.value / tokenPrice;
        log1(
            bytes32(tokensToBuy),
            bytes32(balanceTokens)
        );
        require(tokensToBuy <= balanceTokens);
        voterInfo[msg.sender].voterAddress = msg.sender;
        voterInfo[msg.sender].tokensBought += tokensToBuy;
        balanceTokens -= tokensToBuy;
        return tokensToBuy;
    }

    // This function returns the total votes a candidate has received so far
    function totalVotesFor(bytes32 candidate) public view returns (uint8) {
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }

    // This function increments the vote count for the specified candidate. This
    // is equivalent to casting a vote
    function voteForCandidate(bytes32 candidate, uint8 votesInTokens) public {
        uint index = indexOfCandidate(candidate);
        require(index != uint(-1));

        // msg.sender gives us the address of the account/voter who is trying
        // to call this function
        if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
            for (uint i = 0; i < candidateList.length; i++) {
                voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
            }
        }

        // Make sure this voter has enough tokens to cast the vote
        uint availableTokens = voterInfo[msg.sender].tokensBought - 
            totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
        
        require(availableTokens >= votesInTokens);

        votesReceived[candidate] += votesInTokens;

        // Store how many tokens were used for this candidate
        voterInfo[msg.sender].tokensUsedPerCandidate[index] += votesInTokens;
    }

    function validCandidate(bytes32 candidate) public view returns (bool) {
        for (uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }

    function indexOfCandidate(bytes32 candidate) public view returns (uint) {
        for (uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return i;
            }
        }
        return uint(-1);
    }

    function tokensSold() public view returns (uint) {
        return totalTokens - balanceTokens;
    }

    function getTotalTokens() public view returns (uint) {
        return totalTokens;
    }

    function voterDetails(address user) public view returns (uint, uint[]) {
        return (voterInfo[user].tokensBought, voterInfo[user].tokensUsedPerCandidate);
    }

    /* All the ether sent by voters who purchased the tokens is in this
    contract's account. This method will be used to transfer out all those ethers
    in to another account. *** The way this function is written currently, anyone can call
    this method and transfer the balance in to their account. In reality, you should add
    check to make sure only the owner of this contract can cash out.
    */
    function transferTo(address account) public onlyOwner {
        address myAddress = this;
        account.transfer(myAddress.balance);
    }

    function allCandidates() public view returns (bytes32[]) {
        return candidateList;
    }

    // Function to get candidateList outside of contract since EVM does not allow dynamic sized return type yet.
    function getFixedSizeAllCandidatesArray() public view returns (bytes32[3] array) {
        for (uint i = 0; i < candidateList.length; ++i) {
            array[i] = candidateList[i];
        }
    }

    // Return the sum of all the tokens used by this voter.
    function totalTokensUsed(uint[] _tokensUsedPerCandidate) private pure returns (uint) {
        uint totalUsedTokens = 0;
        for (uint i = 0; i < _tokensUsedPerCandidate.length; i++) {
            totalUsedTokens += _tokensUsedPerCandidate[i];
        }
        return totalUsedTokens;
    }
}
