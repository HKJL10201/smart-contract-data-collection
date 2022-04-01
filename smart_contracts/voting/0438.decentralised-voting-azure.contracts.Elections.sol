pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;
import "./WorkbenchBase.sol";

contract Elections is WorkbenchBase("BallotApplication", "BallotApplication") {

  struct Voter {
    string constituency;
    bool isRegistered;
    bool voted;
    // address vote; //Wallet address of the person voted for
  }

  struct Candidate {
    string name;
    string constituency;
    string politicalParty;
    uint voteCount;
    bool isRegistered;
    address candidateAddress;
  }

  struct Otp {
    uint value;
    bool active;
  }

  //events
  event VotingStarts();
  event VotingEnds();

  //state
  enum ElectionStatus { ContractCreated, VotingStarted, VotingEnded }

  //Roles and properties
  ElectionStatus public State;
  address public ElectionChairperson;
  mapping (address => Candidate) public CandidateList;
  address[] public CandidateAddressList;
  mapping (address => Voter) public VoterList;
  address[] public VoterAddressList;
  mapping (address => Otp) private Otps;

  constructor() public {
    ElectionChairperson = msg.sender;
    State = ElectionStatus.ContractCreated;
  }

  modifier isValidVote(address candidate, address voter, address msgSender, uint otp) {
    require(
      voter == msgSender &&
      CandidateList[candidate].isRegistered == true &&
      VoterList[voter].isRegistered == true &&
      VoterList[voter].voted == false &&
      keccak256(abi.encodePacked(CandidateList[candidate].constituency)) == keccak256(abi.encodePacked(VoterList[voter].constituency)) &&
      Otps[voter].value == otp,
      "Invalid vote!"
    );
    _;
  }
  modifier isAuthorized(address caller) {
    require(caller == ElectionChairperson, "Your are not authorized to call this function!");
    _;
  }

  function getCandidateList() public view returns (Candidate[] memory candidates) {
    candidates = new Candidate[] (CandidateAddressList.length);
    for(uint i = 0; i < CandidateAddressList.length; i++) {
      candidates[i] = CandidateList[CandidateAddressList[i]];
    }
    return candidates;
  }

  function registerCandidate(
    string calldata _name,
    string calldata _constituency,
    string calldata _politicalParty,
    address candidateAddress
  ) external isAuthorized(msg.sender) {
    require(CandidateList[candidateAddress].isRegistered == false, "This candidate wallet address already registered!");
    Candidate memory newCandidate = Candidate({
      name: _name,
      constituency: _constituency,
      politicalParty: _politicalParty,
      voteCount: 0,
      isRegistered: true,
      candidateAddress: candidateAddress
    });
    // Commiting this Cadidate to storage by including it in the CandidateList property
    CandidateList[candidateAddress] = newCandidate;
    CandidateAddressList.push(candidateAddress);
  }

  function registerVoter(
    string calldata _constituency,
    address voterAddress
  ) external isAuthorized(msg.sender) {
    require(VoterList[voterAddress].isRegistered == false, "This voter wallet address already registered!");
    Voter memory newVoter = Voter({
      constituency: _constituency,
      voted: false,
      // vote: address(0),
      isRegistered: true
    });
    VoterList[voterAddress] = newVoter;
    VoterAddressList.push(voterAddress);
  }

  function voteForCandidate(
    address candidate,
    address voter,
    uint otp
  ) external isValidVote(candidate, voter, msg.sender, otp) {
    // VoterList[voter].vote = candidate;
    VoterList[voter].voted = true;
    CandidateList[candidate].voteCount = CandidateList[candidate].voteCount + 1;
    Otps[voter].active = false;
  }

  function mapOTP(uint otp, address voterAddress) external isAuthorized(msg.sender) {
    require(VoterList[voterAddress].isRegistered == true, "This user needs to go through registration to vote!");
    Otp memory newOtp = Otp({
      value: otp,
      active: true
    });
    Otps[voterAddress] = newOtp;
  }

}