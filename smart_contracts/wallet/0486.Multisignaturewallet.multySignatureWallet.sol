// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract wallet {
    string private constant MSG_PREFIX = "coffee and donuts";
    mapping(address => bool) private validSigners;
    uint256 private threshold;
    uint256 public nonce;

    constructor(address[] memory _signers) {
        threshold = _signers.length;
        for (uint256 i = 0; i < threshold; i++) {
            validSigners[_signers[i]] = true;
        }
    }

    bool _lock = true;
    modifier _nonReentrant() {
        require(!_lock);
        _lock = true;
        _;
        _lock = false;
    }

    // function _processWithdrawalInfo(WithdrawInfo calldata _txn, uint256 _nonce)
    //     private
    //     returns (bytes32 _digest)
    // {
    //     bytes memory encoded = abi.encode(_txn);
    //     _digest = keccak256(abi.encodePacked(encoded, _nonce));
    //     _digest = keccak256(abi.encodePacked(MSG_PREFIX, _digest));
    // }

    function verifySign(bytes32 _ethSignedMessageHash, bytes[] calldata _sign)
        public
    {
        uint256 count = _sign.length;
        require(count >= threshold, "not enough signers");
        for (uint256 i = 0; i < count; i++) {
            bytes memory signature = _sign[i];
            address signerAddress = recoverSigner(
                _ethSignedMessageHash,
                signature
            );
            require(validSigners[signerAddress], "not part of consortium");
        }
    }

    function trnsferEth(address _to, uint256 _amount) public {
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "can not process transction");
    }

    function getMessageHash(string memory _message, uint _nonce)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {}

    function withdrawEth(
        address _to,
        uint256 _amount,
        bytes32 _ethSignedMessageHash,
        bytes[] calldata _sign
    ) external {
        verifySign(_ethSignedMessageHash, _sign);
        trnsferEth(_to, _amount);
    }
}

//signA1: 0x12720010836292d3032e8ce2c6e3d1a283a68da73fd879879f1c59a9a73a98f2512b058416860343d6b100e7dd6252ed89f1e514edb3aadbac482bbdd86f56491c
//signA2: 0xfaef491d23b61555ae2cb0566bd1f0b5f66e91f883ad40c94e7d087c7028ed4c4b78d1cc19bbd80aacca2a9f9bb09856da83bf5b3e41ce0d6be12c8d21181e2e1c
//signA3: 0x1dcdfe9531588ede2011033c9adf56c5a08a2282ad793beedf2f6aeea9e253933e84cd7433fb0ec6ed8b16930b303c9694e1058572637143f59a9044b67a501b1c

//0x0c730a2d32b4a4de9f2d96bfcbea25bd648adcf76eb077136090549cc4daf84a
// ["0xa799c2b72e25dB4c8Ea8f9D9e7690fac859c5cee","0x9c8Be6d3F97F506ba105DBcb7A26C2ACE4d88575","0x88B70A483F2E69823D1CFdbD0BD54E93AC1AE53a"]
//[1000, "0xa799c2b72e25db4c8ea8f9d9e7690fac859c5cee"]
// ["0x51f871f0b1c9441463cde5f0e2dcb0831513f84a45bdb7349f0f05aa07ec1c5645e8c4263f39c08dea4db59df219ae3cbf21d0ec5fb7b43812575887911d82851c","0xd267c91a0d829cfd82b1703da3eb3d80d1f672e1d8123138dc974a4c51d421733eae44356adac4dedc44c7f5342b5fb68e5e6b6c4f9701d84a162a43040a85f01c","0x9747386d0d9138e80d4443fa65071940d0c07f45605a6252460322c6accc3e48244e46ff06e18b35fd2cc7497826921412ce42949427ad6912aa38d3daad569b1b"]
