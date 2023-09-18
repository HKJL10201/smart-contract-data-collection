// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import "contracts/utils/ECDSA.sol";
import "contracts/utils/EIP712.sol";
import "../interfaces/INeedStorage.sol";

string constant SIGNING_DOMAIN = "SAY-DAO";
string constant SIGNATURE_VERSION = "1";

contract VerifyVoucher is EIP712 {
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    function _digestHash(
        INeedStorage.InitialVoucher calldata _voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 needId,string title,string category,uint256 paid,string deliveryCode,string child,string role,string content)"
                        ),
                        _voucher.needId,
                        keccak256(bytes(_voucher.title)),
                        keccak256(bytes(_voucher.category)),
                        _voucher.paid,
                        keccak256(bytes(_voucher.deliveryCode)),
                        keccak256(bytes(_voucher.child)),
                        keccak256(bytes(_voucher.role)),
                        keccak256(bytes(_voucher.content))
                    )
                )
            );
    }

    // returns signer address
    function _verify(
        INeedStorage.InitialVoucher calldata _voucher
    ) public view virtual returns (address) {
        bytes32 digest = _digestHash(_voucher);
        return ECDSA.recover(digest, _voucher.swSignature);
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
