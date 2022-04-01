pragma solidity ^0.4.0;

import "../installed_contracts/oraclize-api/contracts/usingOraclize.sol";

contract ResultsOracle is usingOraclize
{
    address owner;

    string public diceResult;

    event Log(string message);
    event LogResult(string result);
    event LogUpdate(address indexed _owner, uint indexed _balance);

    function ResultsOracle() payable public
    {
        owner = msg.sender;
        emit LogUpdate(owner, address(this).balance);

        OAR = OraclizeAddrResolverI(0x6f485c8bf6fc43ea212e93bbf8ce046c7f1cb475);

        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        update(0);
    }

    function getBalance() public returns (uint _balance)
    {
        return address(this).balance;
    }

    function() public
    {
        revert();
    }

    function __callback(bytes32 id, string result, bytes proof) public
    {
        require(msg.sender == oraclize_cbAddress());
        diceResult = result;
        emit Log("Result received from oracle");
        emit LogResult(diceResult);
        update(60);
    }

    function update(uint delay) payable public
    {
        if (oraclize_getPrice("URL") > address(this).balance)
        {
            emit Log("Not enough ETH to query dice results");
        } else {
            emit Log("Querying dice results from oracle");
            oraclize_query(delay, "URL", "json(https://hot-dice-api.herokuapp.com/oracle-roll).result");
        }
    }

 }
