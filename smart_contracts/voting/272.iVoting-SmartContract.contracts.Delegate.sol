pragma solidity ^0.5.0;


import "./lib/IVotingPaper.sol";
import "./lib/IBallot.sol";

import "./lib/MaintainerRole.sol";


contract Delegate is MaintainerRole{

	address internal votingPaperAddr;
	address internal ballotAddr;

	mapping (address => mapping(uint256 => bool)) public nonceUsed;

	function delegateDelegated(address _to, uint256 _tokenId, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) external {
		bytes32 _hash = encodeDelegateData(_to, _tokenId, _nonce);
		address _signer = ecrecover(_hash, v, r, s);
		require(nonceUsed[_signer][_nonce]==false, 'Nonce already used!');
		uint256 _surveyId = IBallot(ballotAddr).getTknIdToSurvey(_tokenId);
		uint256 _startSurvey;	// Timestamp di inizio survey
		uint256 _endSurvey;		// Timestamp fine survey
		(_startSurvey, _endSurvey) = IBallot(ballotAddr).getSurveyTiming(_surveyId);
		require(_startSurvey > now, "Survey started!");
		nonceUsed[_signer][_nonce] = true;
		IVotingPaper(votingPaperAddr).transferFrom(_signer, _to, _tokenId);
	}


	function encodeDelegateData(address _to, uint256 _tokenId, uint256 _nonce) public view returns (bytes32){
        return keccak256(abi.encodePacked(_to, _tokenId, _nonce, this));
    }

	function setVotingPaperAddr(address _vpAddr) external onlyMaintainer returns(bool){
		votingPaperAddr = _vpAddr;
	}

	function checkVotingPaperAddr(address _vpAddr) external view returns(bool){
		return votingPaperAddr == _vpAddr;
	}

	function setBallotAddr(address _blAddr) external onlyMaintainer returns(bool){
		ballotAddr = _blAddr;
	}

	function checkBallotAddr(address _blAddr) external view returns(bool){
		return ballotAddr == _blAddr;
	}
}