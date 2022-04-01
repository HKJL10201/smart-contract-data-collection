/* Deprecated solidity proxy call method. Refer to the asm implementation */
pragma solidity ^0.5.11;

/* Proxy contract that makes a call to the dapp contract to modify the dapp's state */
contract proxy {
    // Public variables that are set by the call function.
    bool public res;
    bytes public val;
    bytes public encoded_value;
    bytes public encoding;
    
    /* Events used for debugging */
    event debug(string, bytes);
    event debug(string, uint256);

    // Function that converts a uint256 bytes to address type using assembly
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            // A Ethereum address is 20 bytes long or a uint160 type, thus it's represented by 40 Hex characters
            // Since the original value given is Big endian with left padding, we only need the last 20 hex of the input
            // Which is from Address 24-64

            // Thus all that is needed is to load the last 20 bytes into the "addr" variable which is then returned
            // Basically load from memory position bys + 32
            addr := mload(add(bys,32))
        } 
    }
    
    // Function to get the returned value in address type
    function getReturnedAddress () public view returns (address) {
        return bytesToAddress(val);
    }

    function proxied_call(address addr, string memory fn_signature, uint256 _n) public returns (bytes memory value) {
        return proxied_call(addr, fn_signature, new bytes(_n));
    }
    
    // @Note Problem with this is what if the user wants to pass things like structs and arrays in?
    function proxied_call(address addr, string memory fn_signature, bytes memory _n) public returns (bytes memory value) {
        // 1) Convert fn_signature from string type to bytes type
        // 2) Get the keccak256 hash of the signature
        // 3) Get the first 4 bytes of the signature hash as function selector
        // 4) encode it together with the arguement for the function
        encoded_value = abi.encodePacked(bytes4(keccak256(bytes(fn_signature))), _n);

        // Make a proxied call to the method of given address and catch the result of the call with the returned value
        // Using "call" code, Callee's contract state is modified, whereas caller's contract state is unchanged
        (res, val) = addr.call(encoded_value);
        return val;
    }

    // @Note Pseudo code below, showing a possible flow
    function proxied_call(address addr, string memory fn_signature, bytes memory _n, bytes memory sig) public returns (bytes memory value) {
        // 1) Convert fn_signature from string type to bytes type
        // 2) Get the keccak256 hash of the signature
        // 3) Get the first 4 bytes of the signature hash as function selector
        // 4) encode it together with the arguement for the function

        sigdata = concat(bytes(address), bytes(fn_signature), _n);
        ecrecover(sigdata, sig)
        
        encoding = abi.encodePacked(_n);
        
        emit debug("encoded value is: ", encoding);
        
        encoded_value = abi.encodePacked(bytes4(keccak256(bytes(fn_signature))), encoding);

        // Make a proxied call to the method of given address and catch the result of the call with the returned value
        // Using "call" code, Callee's contract state is modified, whereas caller's contract state is unchanged
        (res, val) = addr.call(encoded_value);
        return val;
    }

    // Wrapper function over proxied_call, with hardcoded function signature
    function callSetN(address addr, uint256 _n) public {
        // encoded_value = abi.encode(bytes4(keccak256("setN(uint256)")), _n);
        proxied_call(addr, "setN(uint256)", _n);
    }

    // Wrapper function over proxied_call, with hardcoded function signature
    function callSetN_getSender(address addr, uint256 _n) public {
        // encoded_value = abi.encode(bytes4(keccak256("setN(uint256)")), _n);
        proxied_call(addr, "setN_getSender(uint256)", _n);
    }
}