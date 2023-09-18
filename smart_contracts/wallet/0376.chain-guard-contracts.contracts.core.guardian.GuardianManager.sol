// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../Account.sol";
import "../../interfaces/ISignatureValidator.sol";
import "hardhat/console.sol";

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

contract GuardianManager is
    Initializable,
    UUPSUpgradeable,
    ISignatureValidatorConstants
{
    address public owner;
    address public executor;
    Account public account;
    uint256 public threshold;
    uint256 public guardianCount;

    mapping(address => bool) public guardians;

    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event ThresholdChanged(uint256 threshold);

    modifier onlyOwner() {
        require(
            msg.sender == owner || msg.sender == address(account),
            "only owner"
        );
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor (aka timelock)");
        _;
    }

    modifier onlyGuardian() {
        require(guardians[msg.sender], "only guardian");
        _;
    }

    /**
     * Initialize parameters of GuardianManager
     * @param _executor the address of the GuardianExecutor
     * @param _account the account address that this contract is managing
     */
    function initialize(
        address _executor,
        Account _account
    ) public initializer {
        executor = _executor;
        account = _account;
        owner = account.owner();
    }

    /**
     * Initial set up for guardians and threshold
     * @param _guardians the list of guardian's address
     * @param _threshold the minimum number of signature required to change owner
     */
    function setupGuardians(
        address[] memory _guardians,
        uint256 _threshold
    ) public onlyOwner {
        require(
            threshold == 0,
            "GuardianManager:: setupGuardians: threshold must be equals 0 when initialize."
        );
        require(
            _threshold > 0,
            "GuardianManager:: setupGuardians: _threshold must be bigger than 0."
        );
        require(
            _guardians.length >= _threshold,
            "GuardianManager:: setupGuardians: _guardians.length must be bigger or equals to _threshold."
        );

        for (uint256 i = 0; i < _guardians.length; i++) {
            address guardian = _guardians[i];
            require(
                guardian != address(0) && guardian != address(this),
                "GuardianManager:: setupGuardians: invalid guardian address."
            );
            require(
                !guardians[guardian],
                "GuardianManager:: setupGuardians: guardian already existed."
            );
            guardians[guardian] = true;
            emit GuardianAdded(guardian);
        }
        guardianCount = _guardians.length;
        threshold = _threshold;
        emit ThresholdChanged(_threshold);
    }

    function setThershold(uint256 _threshold) public onlyExecutor {
        require(
            threshold > 0,
            "GuardianManager:: setThreshold: threshold haven't been setup yet."
        );
        require(
            _threshold > 0 && _threshold <= guardianCount,
            "GuardianManager:: setThreshold: _threshold must be bigger than 0 and smaller or equals to current number of guardians."
        );
        threshold = _threshold;
        emit ThresholdChanged(_threshold);
    }

    function addGuardian(address _guardian) public onlyExecutor {
        require(
            threshold > 0,
            "GuardianManager:: addGuardian: threshold haven't been setup yet."
        );
        require(
            _guardian != address(0) && _guardian != address(this),
            "GuardianManager:: addGuardian: invalid guardian address."
        );
        require(
            !guardians[_guardian],
            "GuardianManager:: addGuardian: guardian already existed."
        );
        guardians[_guardian] = true;
        guardianCount += 1;
        emit GuardianAdded(_guardian);
    }

    function removeGuardian(address _guardian) public onlyExecutor {
        require(
            threshold > 0,
            "GuardianManager:: removeGuardian: threshold haven't been setup yet."
        );
        require(
            _guardian != address(0) && _guardian != address(this),
            "GuardianManager:: removeGuardian: invalid guardian address."
        );
        require(
            guardians[_guardian],
            "GuardianManager:: removeGuardian: guardian not existed."
        );
        require(
            guardianCount > threshold,
            "GuardianManager:: removeGuardian: number of guardians after removed must larger or equal to threshold."
        );
        guardians[_guardian] = false;
        guardianCount -= 1;
        emit GuardianRemoved(_guardian);
    }

    /**
     * change the owner of the current account that this guardian is managing
     * @param dataHash the preimage hash of the calldata
     * @param data the address of new owner
     * @param signatures the signature of the guardians over data
     */
    function changeOwner(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public payable onlyGuardian {
        require(
            checkMultisig(dataHash, data, signatures),
            "GuardianManager:: changeOwner: invalid multi sig"
        );
        account.changeOwner(address(uint160(bytes20(data))));
        owner = address(uint160(bytes20(data)));
    }

    function checkMultisig(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view returns (bool) {
        uint256 _threshold = threshold;
        require(
            _threshold > 0,
            "GuardianManager:: checkMultisig: invalid threshold"
        );
        return checkSignatures(dataHash, data, signatures, threshold);
    }

    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view returns (bool) {
        require(
            signatures.length >= requiredSignatures * 65,
            "GuardianManager:: checkSignatures: invalid signature length"
        );
        uint256 signatureCount = 0;
        address currentGuardian;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                require(
                    keccak256(data) == dataHash,
                    "GuardianManager:: checkSignatures: datahash and hash of the pre-image data do not match."
                );
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentGuardian = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(
                    uint256(s) >= requiredSignatures * 65,
                    "GuardianManager:: checkSignatures: invalid contract signature location: inside static part"
                );

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(
                    uint256(s) + 32 <= signatures.length,
                    "GuardianManager:: checkSignatures: invalid contract signature location: length not present"
                );

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(
                    uint256(s) + 32 + contractSignatureLen <= signatures.length,
                    "GuardianManager:: checkSignatures: invalid contract signature location: data not complete"
                );

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(
                    ISignatureValidator(currentGuardian).isValidSignature(
                        data,
                        contractSignature
                    ) == EIP1271_MAGIC_VALUE,
                    "GuardianManager:: checkSignatures: invalid contract signature provided"
                );
            }
            // else if (v == 1) {
            //     // If v is 1 then it is an approved hash
            //     // When handling approved hashes the address of the approver is encoded into r
            //     currentGuardian = address(uint160(uint256(r)));
            //     // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
            //     require(msg.sender == currentGuardian || approvedHashes[currentGuardian][dataHash] != 0, "GS025");
            // }
            else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentGuardian = ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            dataHash
                        )
                    ),
                    v - 4,
                    r,
                    s
                );
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentGuardian = ecrecover(dataHash, v, r, s);
            }
            if (guardians[currentGuardian]) signatureCount++;
        }
        return signatureCount >= requiredSignatures;
    }

    function signatureSplit(
        bytes memory signatures,
        uint256 pos
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            /**
             * Here we are loading the last 32 bytes, including 31 bytes
             * of 's'. There is no 'mload8' to do this.
             * 'byte' is not working due to the Solidity parser, so lets
             * use the second best option, 'and'
             */
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {
        (newImplementation);
    }
}
