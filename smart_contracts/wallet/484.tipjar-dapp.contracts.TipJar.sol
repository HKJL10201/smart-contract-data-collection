pragma solidity ^0.5.0;

import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";

contract TipJar is GSNRecipient {

    mapping (bytes32 => uint) tips;

    function send(bytes32 _hash) public payable {
        tips[_hash] = msg.value;
    }

    function claim(string memory _id, address _recipient) public {
        bytes32 hash = keccak256(abi.encodePacked(_id));
        if (tips[hash] != 0) {
            _msgSender().transfer(tips[hash]);
            tips[hash] = 0;
        }
    }

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
    ) external view returns (uint256, bytes memory) {
        return _approveRelayedCall();
    }

    function _preRelayedCall(bytes memory context) internal returns (bytes32) {
    }

    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal {
    }

}