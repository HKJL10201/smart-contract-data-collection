pragma solidity ^0.6.6;

interface IStudentApplication {

    function entryPrice() external view returns (uint256);

    function setAnswerSecret(bytes32) external;

    function registerAnswer(bytes32) external;

    function studentAddress() external view returns (address);

    function getHint(uint256) external view returns(bytes32);

    function applicationState() external view returns(uint256);

    function withdrawAllResults(address) external; 

    function withdrawResults(address to, uint256 val) external;

    function payEntryPrice() external;

    function activate() external;

    function expire() external;

    function registerFinalAnswer() external;

    function accountAllowance(uint256, uint256) external;
    
    function viewChallengeMaterial() external view returns (string memory);
}