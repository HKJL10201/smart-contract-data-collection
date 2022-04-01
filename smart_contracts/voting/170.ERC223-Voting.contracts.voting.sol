pragma solidity ^0.4.18;
// We have to specify what version of compiler this code will compile with
import "./jjERC223.sol";
import "./SafeMath.sol";

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


contract Voting is Ownable{
    
  using SafeMath for uint;
  /* mapping field below is equivalent to an associative array or hash.
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer to store the vote count
  */
  
  struct voter{
    uint256 tokenHolding;
    bytes32[] votedCandidate;
    uint256[] tokensUsedPerCandidate; // Array to keep track of votes per candidate.
    /* We have an array of candidates initialized below.
     Every time this voter votes with her tokens, the value at that
     index is incremented. Example, if candidateList array declared
     below has ["Rama", "Nick", "Jose"] and this
     voter votes 10 tokens to Nick, the tokensUsedPerCandidate[1]
     will be incremented by 10.
     */ 
  }
  mapping (address => voter) public voterInfo;
  mapping (bytes32 => uint256) public votesReceived;
  mapping (bytes32 => bool) public isCandidate;
  
  /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
  We will use an array of bytes32 instead to store the list of candidates
  */

  // Voter has right to see list of candidates.
  bytes32[] public candidateList;
  address public tokenAddress;
  jjERC223 public tokenInterface;
  uint256 tokenHoldingInContract;

  /* This is the constructor which will be called once when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of candidates who will be contesting in the election
  */

  function isValidVoter(address voter_addr, uint256 value) public returns (bool){
  
    require(tokenInterface.balanceOf(voter_addr) >= value);
    return true;
  }

  function setTokenAddress(address tokenAddressCandidate) public onlyOwner returns(address){
    if(tokenAddressCandidate != address(0)){
      tokenAddress = tokenAddressCandidate;
      tokenInterface = jjERC223(tokenAddressCandidate);
      return tokenAddress;
    }
  }

  function Voting(bytes32[] candidateNames, address tokenAddressCandidate) public payable {
    setTokenAddress(tokenAddressCandidate);
    addCandidates(candidateNames);
  }

  // This function returns the total votes a candidate has received so far
  function totalVotesFor(bytes32 candidate) view public returns (uint256) {
    // require(indexOfCandidate(candidate)>uint(-1));
    return votesReceived[candidate];
  }
  
  // This function makes possible to see candidates who got votes from the voter before.
  function indexOfCandidate(bytes32[] votedCandidateList, bytes32 candidate) view public returns (uint) {
    for(uint i = 0; i < votedCandidateList.length; i++) {
      if (votedCandidateList[i] == candidate) {
        return i;
      }
    }
    return uint(-1);
  }
  
  // This function increments the vote count for the specified candidate. This
  // is equivalent to casting a vote
  
  function tokenFallback(address from, uint256 votes, bytes32 candidate) external{
      require(isValidVoter(from,votes));
      voteForCandidate(from, votes,candidate);
  }
  
  function voteForCandidate(address _from, uint256 _votes, bytes32 _candidate) internal returns(bool) {
    
    require(isCandidate[_candidate]);
    uint index = indexOfCandidate(voterInfo[_from].votedCandidate,_candidate);
    if(index == uint(-1)){
        voterInfo[_from].votedCandidate.push(_candidate);
        voterInfo[_from].tokensUsedPerCandidate.push(_votes);

    }
    else{
        uint256 votedTokenToCand = voterInfo[_from].tokensUsedPerCandidate[index];
        voterInfo[_from].tokensUsedPerCandidate[index] = votedTokenToCand.add(_votes);
    }

    // Make sure this voter has enough tokens to cast the vote
    voterInfo[_from].tokenHolding = voterInfo[_from].tokenHolding.add(_votes);
    votesReceived[_candidate] = votesReceived[_candidate].add(_votes);
    tokenHoldingInContract = tokenHoldingInContract.add(_votes);
    // Store how many tokens were used for this candidate
    
    // address voting_contract_addr = address(this);
    // tokenAddress.callcode(bytes4(sha3("transfer(address,uint256)")), address(this),votes);
    // tokenInterface.transferFrom(msg.sender,address(this),votes);
    return true;
  }
  
  function addCandidates(bytes32[] candidateNames) public onlyOwner {
    for (uint i=0;i<candidateNames.length;i++){
        candidateList.push(candidateNames[i]);
        isCandidate[candidateNames[i]] = true;
    }
  }

  function allCandidates() view public returns (bytes32[]) {
    return candidateList;
  }  

  function totalToken() view public returns (uint256){
      return tokenHoldingInContract;
  }
  
  function voterDetails(address user) view public returns (bytes32[], uint256[]) {
    return (voterInfo[user].votedCandidate, voterInfo[user].tokensUsedPerCandidate);
  }

  function currentVote() public returns(bytes32[],uint256[]){
    uint256[] memory current = new uint256[](candidateList.length);
      for (uint i=0;i<candidateList.length;i++){
          current[i] = totalVotesFor(candidateList[i]);
      }
    return (candidateList,current);
  }
  
}
