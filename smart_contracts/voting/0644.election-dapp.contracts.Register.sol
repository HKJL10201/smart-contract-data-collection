pragma solidity 0.8.7;

contract Register {

    mapping(address => bool) public EligbleVotersAddresses;
    mapping(bytes32 => bool) public RegisteredStudentHashes;
    mapping(bytes32 => bool) public VerifiedStudentHashes; 


    constructor(bytes32[] memory studentHashes) {
        for (uint32 i = 0; i < studentHashes.length; i++){
            RegisteredStudentHashes[studentHashes[i]] = true;
        }
    }
    
    function addStudentHash(bytes32 studentHash) public {
        if (RegisteredStudentHashes[studentHash] == true)
            revert();        
        else
            RegisteredStudentHashes[studentHash] = true;
    }

    function isEligble(address _address) public view returns(bool) {
        if (EligbleVotersAddresses[_address] == true)
            return true;
        else return false;
    }
    function verify(string memory passcode) public {
        bytes32 hash = sha256(abi.encodePacked(passcode));
        if (VerifiedStudentHashes[hash] == true){
            revert();
        }

        if (RegisteredStudentHashes[hash] == true /*&& VerifiedStudentHashes[hash] == false*/) {
            VerifiedStudentHashes[hash] = true;   // 
            EligbleVotersAddresses[msg.sender] = true;
        }
    }

}