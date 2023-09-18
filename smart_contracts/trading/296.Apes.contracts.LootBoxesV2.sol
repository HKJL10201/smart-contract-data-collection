// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IApes.sol";
import "./interface/ITraits.sol";
import "./interface/IRandomizer.sol";
import "./interface/IMasterContract.sol";

contract LootBoxesV2 is ERC1155Holder, Ownable, ReentrancyGuard {
    uint256 public powerCooldown = 12 hours;

    IApes public apesContract;
    ITraits public traitsContract;
    IRandomizer public randomizerContract;
    IMasterContract public masterContract;
    address public secret;

    mapping(uint256 => uint256) public lastBoxOpen;
    mapping(uint256 => uint256) public apeLastBox;
    mapping(uint256 => uint256) public apeOpenCount;

    mapping(bytes => bool) public isSignatureUsed;

    event BoxOpened(
        uint256 boxType,
        uint256 apeId,
        uint256 amount,
        uint256[] prizes
    );

    constructor(
        address _apesAddress,
        address _traitsAddress,
        address _randomizerAddress,
        address _masterContract,
        address _secret
    ) {
        apesContract = IApes(_apesAddress);
        traitsContract = ITraits(_traitsAddress);
        randomizerContract = IRandomizer(_randomizerAddress);
        masterContract = IMasterContract(_masterContract);
        secret = _secret;
    }

    function openCommonBox(
        uint256 apeId,
        uint256 amount,
        uint256 price,
        uint256 boxType,
        uint256 timeOut,
        bool hasPower,
        bytes calldata randomSeed,
        bytes calldata signature
    ) external payable {
        require(!isSignatureUsed[signature], "OpenBox: Signature already used");
        require(timeOut > block.timestamp, "OpenBox: Seed is no longer valid");
        require(boxType == 0, "OpenBox: BoxType not valid");

        address tokenOwner = apesContract.ownerOf(apeId); // Current owner of the Ape, allows SafeClaim

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        tokenOwner,
                        apeId,
                        amount,
                        price,
                        boxType,
                        timeOut,
                        hasPower,
                        randomSeed
                    )
                ),
                signature
            ),
            "OpenBox: Signature is invalid"
        );

        isSignatureUsed[signature] = true;

        if (!hasPower || apeLastBox[apeId] + powerCooldown > block.timestamp) {
            require(
                apeLastBox[apeId] + 5 minutes > block.timestamp,
                "OpenBox: Re open time elapsed"
            );

            if (apeOpenCount[apeId] > 0) {
                price = price * 2; // 2X the price
            } else {
                price = (price * 3000) / 2000; // 3/2 of the price
                apeOpenCount[apeId]++;
            }
        } else {
            apeOpenCount[apeId] = 0;
        }

        masterContract.pay(price, price);

        (uint256[] memory prizes, bool hasExtra) = randomizerContract.getRandom(
            randomSeed,
            amount
        );

        uint256[] memory prizesAmounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            prizesAmounts[i] = 1;
        }

        traitsContract.mintBatch(msg.sender, prizes, prizesAmounts);

        emit BoxOpened(boxType, apeId, amount, prizes);
    }

    function openSpecialBox(
        uint256 apeId,
        uint256 amount,
        uint256 price,
        uint256 boxType,
        uint256 timeOut,
        bytes calldata randomSeed,
        bytes calldata signature
    ) external payable {
        require(!isSignatureUsed[signature], "OpenBox: Signature already used");
        require(timeOut > block.timestamp, "OpenBox: Seed is no longer valid");
        require(boxType > 0, "OpenBox: BoxType not valid");
        require(msg.value == price, "OpenBox: Wrong ETH value");

        address tokenOwner = apesContract.ownerOf(apeId); // Current owner of the Ape, allows SafeClaim

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        tokenOwner,
                        apeId,
                        amount,
                        price,
                        boxType,
                        timeOut,
                        randomSeed
                    )
                ),
                signature
            ),
            "OpenBox: Signature is invalid"
        );

        isSignatureUsed[signature] = true;

        (uint256[] memory prizes, bool hasExtra) = randomizerContract.getRandom(
            randomSeed,
            amount
        );

        uint256 quantiteToMint = amount;

        if (hasExtra) {
            for (uint256 i = 0; i < prizes.length; i++) {
                uint256 currentPrize = prizes[i];

                if (currentPrize > 39 && currentPrize < 44) {
                    masterContract.airdrop(msg.sender, 1, currentPrize); // Number between 40 - 43, breeding replenishment
                    quantiteToMint--;
                }
            }

            if (quantiteToMint > 0) {
                uint256[] memory prizesToMint = new uint256[](quantiteToMint);
                uint256[] memory prizesAmounts = new uint256[](quantiteToMint);
                uint256 addedCount;

                for (uint256 i = 0; i < prizes.length; i++) {
                    uint256 currentPrize = prizes[i];
                    if (currentPrize > 39 && currentPrize < 44) {
                        continue;
                    }

                    prizesAmounts[addedCount] = 1;
                    prizesToMint[addedCount] = currentPrize;
                    addedCount++;
                }

                traitsContract.mintBatch(
                    msg.sender,
                    prizesToMint,
                    prizesAmounts
                );
            }
        } else {
            uint256[] memory prizesAmounts = new uint256[](quantiteToMint);

            for (uint256 i = 0; i < quantiteToMint; i++) {
                prizesAmounts[i] = 1;
            }

            traitsContract.mintBatch(msg.sender, prizes, prizesAmounts);
        }

        emit BoxOpened(boxType, apeId, amount, prizes);
    }

    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function setContractAddresses(
        address _apesAddress,
        address _traitsAddress,
        address _randomizerAddress,
        address _masterContract
    ) external onlyOwner {
        apesContract = IApes(_apesAddress);
        traitsContract = ITraits(_traitsAddress);
        randomizerContract = IRandomizer(_randomizerAddress);
        masterContract = IMasterContract(_masterContract);
    }

    function withdrawETH(address _address, uint256 amount)
        public
        nonReentrant
        onlyOwner
    {
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");
        require(success, "Unable to send eth");
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}
