pragma solidity ^ 0.5.1;


contract Bid {
    /// @notice This function generates the nonce and the hash needed in the Vickrey Auction.
    /// @param _bidValue is the desired bid.
    function generate(uint _bidValue) public view returns(uint, bytes32, bytes32) {
        
        uint value;
        bytes32 nonce;
        bytes32 hash;

        value = _bidValue;
        nonce = sha256(abi.encodePacked(block.timestamp));
        hash = sha256(abi.encodePacked(_bidValue, nonce));

        return (value, nonce, hash);
    }
}