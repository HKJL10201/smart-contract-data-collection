pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/GSN/GSNRecipient.sol";

interface MCD {
    function approve(address usr, uint wad) external returns (bool);
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address holder) external returns(uint);
}

contract DaiGasless is GSNRecipient {


    MCD MCDContract;
    address RevenueAddress;
   
    constructor(address MCDaddress, address _RevenueAddress) public {
        MCDContract = MCD(MCDaddress);
        RevenueAddress = _RevenueAddress;
        
        }


    function send(address to, uint value, uint fee) public{
    require(MCDContract.balanceOf(msg.sender)>value + fee);
        MCDContract.transferFrom(msg.sender, to, value);
        MCDContract.transferFrom(msg.sender, RevenueAddress, fee);
    }


//-- The below function support open zeppelin relayed calls --//
    
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view override returns (uint256, bytes memory) {
        return _approveRelayedCall();
    }

    // We won't do any pre or post processing, so leave _preRelayedCall and _postRelayedCall empty
    function _preRelayedCall(bytes memory context) internal override returns (bytes32) {
    }

    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal override {
    }
    

}
