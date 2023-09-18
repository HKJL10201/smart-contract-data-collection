pragma solidity ^0.5.0;


interface IBallot {



	function getSurveyList(uint256) external view returns(uint256, uint256, uint256, address, string memory);

	function getSurveyTiming(uint256 _surveyId) external view returns(uint256, uint256);

	function getTknIdToSurvey(uint256) external view returns(uint256);

	function createSurvey(uint256 _startSurvey, uint256 _endSurvey, bytes32[] calldata _hashAnswers,  uint256 _multipleAnswer, string calldata _uri, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) external returns (uint256);

	function getSurveyMetadata(uint256 _id) external view returns(uint256, uint256, uint256, address, string memory);

	function addParticipants(uint256 _surveyId, address[] calldata _participants, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) external returns(bool);

	function vote(uint256 _surveyId, uint256[] calldata _response, uint256 _nonce,  uint8 v, bytes32 r, bytes32 s) external returns (bool);

	function setSurveyGraceTime(uint256 _surveyId, uint256 _newGraceTime) external;

	function encodeSurveyData(uint256 _startSurvey, uint256 _endSurvey, bytes32[] calldata _hashAnswers,  uint256 _multipleAnswer, string calldata _uri, uint256 _nonce) external view returns (bytes32);

    function encodeAddParticipantsData(uint256 _surveyId, address[] calldata _participants, uint256 _nonce) external view returns(bytes32);

    function encodeVoteData(uint256 _surveyId, uint256[] calldata _response, uint256 _nonce) external view returns (bytes32);


	function setVotingPaperAddr(address _vpAddr) external returns(bool);

	function checkVotingPaperAddr(address _vpAddr) external view returns(bool);

}
