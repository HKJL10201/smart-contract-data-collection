pragma solidity >=0.5.0;

import "./oraclizeAPI.sol";

contract OracleAda is usingOraclize {

    event CurrentOracleFeeEvent(uint _oracleFee);
    event QuerySentEvent(string _description);
    event QueryNotSentEvent(string _description);
    event QueryFinishedEvent(string _description);

    address payable private owner;

    bool private testMode = false;
    string private randomQuery = "https://www.random.org/integer-sets/?sets=1&num=4&min=1&max=24&seqnos=on&commas=on&sort=on&order=index&format=plain&rnd=new";
    mapping(bytes32 => string) private generatedNumbers;
    mapping(bytes32 => bool) private isQueryProcessedByQueryId;

    constructor(bool _testMode, bool _privateNetwork) public payable {
        owner = msg.sender;
        if (_privateNetwork) {
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        }
        testMode = _testMode;
    }

    function() external payable {
        // Fallback 'payable' function is needed for a contract to accept ETH payments.
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Function can only be executed by contract owner.");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function retrieveProfit() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function activateTestMode(bool _activateTestMode) public onlyOwner {
        testMode = _activateTestMode;
    }

    function generateRandomNumber() public returns (bytes32) {
        uint oracleFee = oraclize_getPrice("URL");
        emit CurrentOracleFeeEvent(oracleFee);

        bytes32 queryId;
        if (oracleFee <= address(this).balance) {
            queryId = oraclize_query("URL", randomQuery);
            emit QuerySentEvent("Oraclize query was sent, waiting for the answer...");
        } else {
            emit QueryNotSentEvent("Oraclize query was not sent, please add some ETH to cover for the query fee.");
        }

        return queryId;
    }

    function __callback(bytes32 queryId, string memory result) public {
        require(msg.sender == oraclize_cbAddress());

        isQueryProcessedByQueryId[queryId] = true;
        if (testMode) {
            generatedNumbers[queryId] = "Set 1: 1, 2, 3, 4";
        } else {
            generatedNumbers[queryId] = result;
        }
        emit QueryFinishedEvent('Oraclize query was successful.');
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Getters
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function isQueryProcessed(bytes32 queryId) public view returns (bool) {
        return isQueryProcessedByQueryId[queryId];
    }

    function getRandomNumber(bytes32 queryId) public view returns(string memory) {
        return generatedNumbers[queryId];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
