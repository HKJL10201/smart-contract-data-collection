pragma solidity ^0.5.0;

import "./lib/IVotingPaper.sol";
import "./lib/IBallot.sol";

import "./lib/MaintainerRole.sol";
import "./lib/SignerRole.sol";


contract Ballot is IBallot, MaintainerRole, SignerRole{

	address internal votingPaperAddr;

	struct SurveyInfo{

		uint256 startSurvey;	// Timestamp di inizio survey
		uint256 endSurvey;		// Timestamp fine survey
		uint256 nAnswers;
		address owner;
		string uri;
	}

	mapping (uint256 => SurveyInfo) public surveyList;
	mapping (uint256 => uint256[]) public surveyTknList;
	mapping (address => mapping(uint256 => uint256[])) public addressToSurveyTknId;
	mapping	(uint256 => uint256) public tknIdToSurvey;

	uint256 internal basicGraceTime = 10;
	mapping (uint256 => uint256) public surveyGraceTime;

	mapping (address => mapping(uint256 => bool)) public nonceUsed;

	event surveyChoices(uint256 indexed _surveyId, bytes32[] _hashAnswers);
	event newSurvey(uint256 indexed _surveyId, address indexed creator, uint256 indexed num_multipleAnswers);
	event voted (uint256 indexed _surveyId, address indexed _address, uint256 indexed _answer, bytes32 _hash);
	event newParticipants(uint256 indexed _surveyId, address[] _participants);


	
	uint256 public surveyId = 1;


	function createSurvey(uint256 _startSurvey, uint256 _endSurvey, bytes32[] calldata _hashAnswers,  uint256 _multipleAnswer, string calldata _uri, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) external returns (uint256)
	{

		//NOTA: in genere faccio bytes32 _hash =  encodeSurveyData(_startSurvey, _endSurvey, _hashAnswers, _multipleAnswer, _uri, _nonce);
		// Sembra che per ogni funzione io possa definire al massimo 16 variabili
		// https://blog.aventus.io/stack-too-deep-error-in-solidity-5b8861891bae
		address _signer = ecrecover( encodeSurveyData(_startSurvey, _endSurvey, _hashAnswers, _multipleAnswer, _uri, _nonce), v, r, s);
		require(nonceUsed[_signer][_nonce]==false, 'Nonce already used!');
		require(isSigner(_signer), "User can't create survey!");
		require(_startSurvey < _endSurvey, 'End survey before start!');
		require(_startSurvey > now, 'Start must be in the future');
		nonceUsed[_signer][_nonce] = true;
		SurveyInfo memory surveyInfo = SurveyInfo({
				startSurvey: _startSurvey,
				endSurvey: _endSurvey,
				owner: _signer,
 				nAnswers: _multipleAnswer,
 				uri: _uri
	 		});
		surveyList[surveyId] = surveyInfo;
		surveyGraceTime[surveyId] = basicGraceTime;
		emit newSurvey(surveyId, msg.sender, _multipleAnswer);
		emit surveyChoices(surveyId, _hashAnswers);
		surveyId = surveyId + 1;
		return surveyId-1;
	}

	function getTime() public view returns(uint256){
		return now;
	}

	function getSurveyMetadata(uint256 _id) external view returns(uint256, uint256, uint256, address, string memory){
		return (surveyList[_id].startSurvey, surveyList[_id].endSurvey, surveyList[_id].nAnswers, surveyList[_id].owner, surveyList[_id].uri);
	}

	function addParticipants(uint256 _surveyId, address[] calldata _participants, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) external returns(bool){
		bytes32 _hash = encodeAddParticipantsData(_surveyId, _participants, _nonce);
		address _signer = ecrecover(_hash, v, r, s);
		require(nonceUsed[_signer][_nonce]==false, 'Nonce already used!');
		require(isSigner(_signer), "User can't add participants!");
		require(surveyList[_surveyId].startSurvey > now, "Survey started. Can't add participants");
		require(surveyList[_surveyId].owner == _signer, "This user cant'd add participants!");
		nonceUsed[_signer][_nonce] = true;
		uint256 _tknGenId = 0;
		for (uint256 i=0; i<_participants.length; i++){
			for (uint256 j=0; j<surveyList[_surveyId].nAnswers; j++){
				_tknGenId = IVotingPaper(votingPaperAddr).mint(_surveyId, _participants[i], _participants[i]);
				surveyTknList[_surveyId].push(_tknGenId);
				addressToSurveyTknId[_participants[i]][_surveyId].push(_tknGenId);
				tknIdToSurvey[_tknGenId] = _surveyId;
			}
		}
		emit newParticipants(_surveyId, _participants);
		return true;
	}

	// Nota: se l'utente ha votato parzialmente, cmq non può più votare
	function vote(uint256 _surveyId, uint256[] calldata _response, uint256 _nonce,  uint8 v, bytes32 r, bytes32 s) external returns (bool){
		bytes32 _hash = encodeVoteData(_surveyId, _response, _nonce);
		address _signer = ecrecover(_hash, v, r, s);
		require(nonceUsed[_signer][_nonce]==false, 'Nonce already used!');
		require(surveyList[_surveyId].startSurvey < now, "Survey not started!");
		require(surveyList[_surveyId].endSurvey+surveyGraceTime[_surveyId] > now, "Survey finished!");
		nonceUsed[_signer][_nonce] = true;
		uint256 _tknId = 0; 
		for (uint256 i=0; i< _response.length; i++){
			_tknId = addressToSurveyTknId[_signer][_surveyId][i];
			require(_tknId != 0, "Token id is not valid");
			IVotingPaper(votingPaperAddr).vote(_signer, _surveyId, _tknId, _response[i]);
			emit voted(_surveyId, _signer, _response[i], keccak256(abi.encodePacked(_surveyId, _response[i])));
		}
	}

	function setSurveyGraceTime(uint256 _surveyId, uint256 _newGraceTime) external onlyMaintainer {
		require(surveyList[_surveyId].endSurvey+surveyGraceTime[_surveyId] > now, "Survey finished!");
		surveyGraceTime[_surveyId] = _newGraceTime;
	}

	function encodeSurveyData(uint256 _startSurvey, uint256 _endSurvey, bytes32[] memory _hashAnswers,  uint256 _multipleAnswer, string memory _uri, uint256 _nonce) public view returns (bytes32){
        return keccak256(abi.encodePacked(_startSurvey, _endSurvey, _hashAnswers, _multipleAnswer, _uri, _nonce, this));
    }

    function encodeAddParticipantsData(uint256 _surveyId, address[] memory _participants, uint256 _nonce) public view returns(bytes32){
    	return keccak256(abi.encodePacked(_surveyId, _participants, _nonce, this));
    }

    function encodeVoteData(uint256 _surveyId, uint256[] memory _response, uint256 _nonce) public view returns (bytes32){
    	return keccak256(abi.encodePacked(_surveyId, _response, _nonce, this));
    }


	function setVotingPaperAddr(address _vpAddr) external onlyMaintainer returns(bool){
		votingPaperAddr = _vpAddr;
	}

	function checkVotingPaperAddr(address _vpAddr) external view returns(bool){
		return votingPaperAddr == _vpAddr;
	}

	function getSurveyList(uint256 _surveyId) external view returns(uint256, uint256, uint256, address, string memory){
		return (surveyList[_surveyId].startSurvey, surveyList[_surveyId].endSurvey, surveyList[_surveyId].nAnswers, surveyList[_surveyId].owner, surveyList[_surveyId].uri);
	}

	function getSurveyTiming(uint256 _surveyId) external view returns(uint256, uint256){
		return (surveyList[_surveyId].startSurvey, surveyList[_surveyId].endSurvey);
	}

	function getTknIdToSurvey(uint256 _surveyId) external view returns(uint256){
		return tknIdToSurvey[_surveyId];
	}

}
