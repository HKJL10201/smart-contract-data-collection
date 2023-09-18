pragma solidity ^0.4.21;

/**
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract RandomLottery is usingOraclize {
    
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    event proofVerifyFail(string);
    uint randomValue;

    function RandomLottery() {
        OAR = OraclizeAddrResolverI(resolve_addr);  
        oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof in the constructor
        update(); // let's ask for N random bytes immediately when the contract is created!
    }
    
    // the callback function is called by Oraclize when the result is ready
    // the oraclize_randomDS_proofVerify modifier prevents an invalid proof to execute this function code:
    // the proof validity is fully verified on-chain
    function __callback(bytes32 _queryId, string _result, bytes _proof)
    { 
        if (msg.sender != oraclize_cbAddress()) throw;
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
            proofVerifyFail(string("Proof Verification Failed!"));
        } else {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..
            
            newRandomNumber_bytes(bytes(_result)); // this is the resulting random number (bytes)
            
            // for simplicity of use, let's also convert the random bytes to uint if we need
            uint maxRange = 6; // this is the highest uint we want to get. It should never be greater than 6, where N is the number of random bytes we had asked the datasource to return
            randomValue = uint(sha3(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange) range
            
            newRandomNumber_uint(randomValue); // this is the resulting random number (uint)
        }
    }
    
    function update() payable {
        uint N = 1; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 200000; // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId
    }
    
    function getLotteryRand() internal returns (uint random){
       update();
       return  randomValue%6;
    }
}
*/
contract RandomLottery  {
    function getLotteryRand() internal returns (uint random) {
/*       bytes storage current = bytes(now);
       bytes32 random1 = sha256(current);
       bytes storage current2 = bytes(now);
       bytes20 random2 = ripemd160(current2);*/
       random = addmod(now, now, 7773);
       random = mulmod(random, now, 6) + 1;
}
}
