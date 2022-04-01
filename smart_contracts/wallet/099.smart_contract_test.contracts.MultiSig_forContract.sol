pragma solidity >=0.4.22 <0.9.0;

/*We define a data structure (struct Contract) to store the data associated with each contract
(the hash of the contract, finish deadline, signatures, and status of the contract) and indexed
by idE . All these data are provided by the signatory who calls the f inish function and are
verified by the SC before establishing its status (as explained below). A new data structure
is created for each multi-party contract signing that requires the SC to be called. Note that
no confidential data are stored in the SC data structure; that is, the content of the contract,
M, cannot be recovered by anyone from the signatures or the stored hash of the contract.*/

contract MultiSig {
    /*Data structure associated with each exchange identifier (idE ) requiring the use of
    the blockchain */
    struct Contract{
        bytes32 hashContract;
        uint deadline;
        bytes [] signatures;
        bool finished;
    }

    mapping(bytes32 => Contract) exchanges;

    //Code of the finish function
    /* finish: given a contract identifier, any signatory can provide all signatures on the 
    contract, before it expires, establishing the status of the contract as finished. */
    function finish(bytes32 _idE, uint _deadline, uint _index, bytes32 _hashContract, 
    address[] memory _signatories, bytes[] memory _signatures) public returns (string memory) {

        require(! exchanges[_idE].finished, "Contract already finished ");
        require(block.timestamp <= _deadline, "Contract not finished - Time exceeded ");
        require( _signatories[_index] == msg.sender, "Contract not finished - Invalid signatory ");
        bytes32 idE = keccak256(abi.encodePacked(_hashContract, _signatories, _deadline, address(this)));
        require(idE == _idE," Contract not finished - Wrong idE");
        bytes32 htosign = keccak256(abi.encodePacked(idE, _hashContract, _signatories, _deadline, address(this)));

        for(uint i = 0; i < _signatories.length; i++){
            address signatory = _signatories[i];
            bytes memory signature = _signatures[i];
            require(isValidData(htosign , signatory , signature),
            "Contract not finished - Invalid signature ");
            exchanges[_idE].signatures.push(signature);
        }
        exchanges[_idE].hashContract = _hashContract;
        exchanges[_idE].deadline=_deadline;
        exchanges[_idE].finished=true;
        return (" Contract finished ");
    }

    //Verifying the contract signature for each signatory
    function isValidData(bytes32 _htosign, address _signer, bytes memory _signature) 
    private pure returns(bool){
        return(recoverSigner(_htosign, _signature) == _signer);
    }


    /// signature methods.
    function splitSignature(bytes memory sig)internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
    ///
    function recoverSigner(bytes32 resumen, bytes memory sig) private pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(resumen, v, r, s);
    }

    //Code of the query function.
    /* query: given a contract identifier, any signatory may check the status of the con-
    tract, obtaining all signatures if the contract was previously finished by one of the
    signatories. */
    function query(bytes32 _idE) public view returns (string memory, bytes [] memory) {
        if(! exchanges[_idE].finished){
            return (" Contract doesnt exist",exchanges[_idE].signatures);
        }
        return (" Contract finished",exchanges[_idE].signatures);
    }

}
