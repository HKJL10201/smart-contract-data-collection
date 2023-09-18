pragma solidity >=0.4.16 <0.7.0;

    contract MultiSig{
        
        uint256 public nonce;
        uint public requiredSignatures;
        mapping (address => bool) public isOwner;
        address[] public ownersArr;
                
        
        constructor(uint requiredSignatures_, address[] memory owners_) public {
            require(owners_.length <= 10 && requiredSignatures_ <= owners_.length && requiredSignatures_ > 0, "checking that they're not empty");
        
            address lastAdd = address(0); // owner cannot have address (0)
            //checks to make sure owners address is greater than address(0)
            for (uint i = 0; i < owners_.length; i++) {
                  isOwner[owners_[i]] = true;
                  lastAdd = owners_[i];
                }
                ownersArr = owners_;
                requiredSignatures = requiredSignatures_;
            }
        
       function execute(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, address destination, uint value, bytes memory data) public  {
            if (sigR.length != requiredSignatures) {revert();}
            if (sigR.length != sigS.length || sigR.length != sigV.length) {revert();}
            
            bytes32 txHash = keccak256(abi.encodePacked(byte(0x19), byte(0), this, destination, value, data, nonce));

            
            address lastAdd = address(0); 
            for (uint i = 0; i < requiredSignatures; i++) {
                address recovered = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
                if (recovered <= lastAdd || !isOwner[recovered]) revert();
                lastAdd = recovered;
                nonce = nonce + 1;
                (bool success,) = destination.call.value(value)(data);
                require(success);
    }

    }
    function () payable external{}
    }