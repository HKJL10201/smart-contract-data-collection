// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "./Candidate.sol";

contract Campaign {

  string name;
  address campaignOwner;
  bool isActive;

  Candidate[] candidates;
  mapping(string => bool) isCandidateExists;
  mapping(address => bool) isAddressExists;

  uint voteCount;
  mapping(address => bool) isVoterVotes;

  event CandidateCreated(address candidateAddress, string candidateName);
  event UserVoted();
  event VotingEnded();


  constructor(string memory _name, address _campaignOwner) {
    name = _name;
    isActive = true;
    campaignOwner = _campaignOwner;
  }

  // SETTERS

  function createCandidate(string memory _candidateName) public {
    require(bytes(_candidateName).length > 0 && !isCandidateExists[_candidateName]);
    require(isActive, 'Cannot add new candidates to not active campaign');

    Candidate _candidate = new Candidate(_candidateName);
    candidates.push(_candidate);

    isCandidateExists[_candidateName] = true;

    address candidateAddress = address(_candidate);
    isAddressExists[candidateAddress] = true;

    emit CandidateCreated(candidateAddress, _candidateName);
  }

  function voteForCandidate(address candidateAddress) public payable {
    require(isAddressExists[candidateAddress] && !isVoterVotes[msg.sender]);
    require(msg.value >= 1, 'Minimal payment for voting is 1 wei');
    require(isActive, 'This campaign is not active. You can only view results.');

    Candidate candidate = Candidate(candidateAddress);
    candidate.vote();

    voteCount++;
    isVoterVotes[msg.sender] = true;
    emit UserVoted();
  }

  function endTheVoting() public {
    require(msg.sender == campaignOwner, 'Only owner can end the voting.');
    require(isActive, 'You cannot end not active campaign.');

    uint actualBalance = address(this).balance;

    address payable _address = payable(msg.sender);

    if(_address.send(actualBalance)){
      isActive = false;
      emit VotingEnded();
    }
  }


  // GETTERS

  function getCampaignInfo() public view returns (string memory _name, uint _voteCount, bool _userCanVote, address [] memory _candidatesAddresses, bool _isActive, bool _userIsOwner) {
    (_name, _voteCount, _userCanVote, _candidatesAddresses, _isActive, _userIsOwner) = getCampaignInfo(msg.sender);
  }

  function getCampaignInfo(address senderAddress) public view returns (string memory _name, uint _voteCount, bool _userCanVote, address [] memory _candidatesAddresses, bool _isActive, bool _userIsOwner) {
    address[] memory _addresses = new address[](candidates.length);
    for(uint i; i< candidates.length; i++){
      _addresses[i] = address(candidates[i]);
    }

    _name = name;
    _voteCount = voteCount;
    _userCanVote = !isVoterVotes[msg.sender];
    _candidatesAddresses = _addresses;
    _isActive = isActive;
    _userIsOwner = msg.sender == campaignOwner;
    _userIsOwner = senderAddress == campaignOwner;

  }


  function getCandidateNameById(address candidateAddress) public view returns (string memory _candidateName) {
    require(isAddressExists[candidateAddress]);
    (_candidateName) = Candidate(candidateAddress).getName();
  }

  function getName() public view returns (string memory _name) {
    _name = name;
  }

  function getResults() public view returns  (address [] memory _candidateAddresses, uint[] memory _candidateVoteCounts, uint _generalVoteCount){
    require(!isActive, 'Cannot view results of active campaign');
    require(candidates.length > 0, 'Empty results. No candidates.');
    require(voteCount > 0, 'No vote count.');

    address[] memory _addresses = new address[](candidates.length);
    uint[] memory _voteCount = new uint[](candidates.length);

    for(uint i; i< candidates.length; i++){
      Candidate _candidate = Candidate(candidates[i]);
      _addresses[i] = address(candidates[i]);
      _voteCount[i] = _candidate.getVoteCount();
    }

    _candidateAddresses = _addresses;
    _candidateVoteCounts = _voteCount;
    _generalVoteCount = voteCount;
  }

}
