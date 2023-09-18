// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IApes.sol";
import "./interface/ITraits.sol";
import "./interface/IRandomizer.sol";

contract LootBoxes is ERC1155Holder, Ownable, ReentrancyGuard {
    uint256 public boxesAmount;
    uint256 public priceTimeFrame = 15 minutes;
    uint256 public powerCooldown = 12 hours;
    uint256 public increasePercentage = 200; // 2%
    uint256 public decreasePercentage = 100; // 1%

    uint256[] public discounts = [1000, 2500];

    IApes public apesContract;
    ITraits public traitsContract;
    IRandomizer public randomizerContract;
    IERC20 public methContract;
    address public secret;
    address public treasury;

    mapping(uint256 => LootBox) public boxInfo;

    mapping(uint256 => uint256) public lastBoxOpen;
    mapping(uint256 => uint256) public lastBoxIncrease;
    mapping(uint256 => uint256) public apeLastBox;
    mapping(uint256 => uint256) public apeOpenCount;

    mapping(uint256 => bool) public freeSpinUsed;

    mapping(address => bool) public isBoxCreator;

    mapping(bytes => bool) public isSignatureUsed;

    struct LootBox {
        uint256 boxType; // 0 - common, 1 - Legendary, 1 - Epic
        uint256 currentPrice;
        uint256 minPrice;
        uint256 maxPrice;
    }

    event BoxOpened(
        uint256 boxId,
        uint256 boxType,
        uint256 apeId,
        uint256 amount,
        uint256[] prizes
    );

    event BoxCreated(
        uint256 boxType,
        uint256 initialPrice,
        uint256 minPrice,
        uint256 maxPrice,
        address operator
    );

    constructor(
        address _apesAddress,
        address _traitsAddress,
        address _randomizerAddress,
        address _methAddress,
        address _secret,
        address _treasury
    ) {
        apesContract = IApes(_apesAddress);
        traitsContract = ITraits(_traitsAddress);
        randomizerContract = IRandomizer(_randomizerAddress);
        methContract = IERC20(_methAddress);
        secret = _secret;
        treasury = _treasury;
    }

    function createBox(
        uint256 boxType,
        uint256 initialPrice,
        uint256 minPrice,
        uint256 maxPrice
    ) external {
        require(isBoxCreator[msg.sender], "CreateBox: Sender not allowed");

        uint256 boxId = boxesAmount;

        // SAVE LOOT BOX INFO
        boxInfo[boxId] = LootBox({
            boxType: boxType,
            currentPrice: initialPrice,
            minPrice: minPrice,
            maxPrice: maxPrice
        });

        lastBoxOpen[boxId] = block.timestamp;
        lastBoxIncrease[boxId] = block.timestamp;

        boxesAmount++;

        emit BoxCreated(boxType, initialPrice, minPrice, maxPrice, msg.sender);
    }

    function openBox(
        uint256 boxId,
        uint256 apeId,
        uint256 amount,
        uint256 timeOut,
        bool hasPower,
        bytes memory randomSeed,
        bytes memory signature
    ) external payable nonReentrant {
        require(!isSignatureUsed[signature], "OpenBox: Signature already used");
        require(timeOut > block.timestamp, "OpenBox: Seed is no longer valid");

        address tokenOwner = apesContract.ownerOf(apeId); // Current owner of the Ape, allows SafeClaim

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        tokenOwner,
                        boxId,
                        apeId,
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

        uint256 lastPrice = getPrice(boxId);

        if (boxInfo[boxId].currentPrice < lastPrice) {
            lastBoxIncrease[boxId] = block.timestamp;
        }

        boxInfo[boxId].currentPrice = lastPrice;

        uint256 boxType = boxInfo[boxId].boxType;

        if (!hasPower || apeLastBox[apeId] + powerCooldown > block.timestamp) {
            if (boxType > 0) {
                uint256 discount = 0;

                if (amount > 10) {
                    discount = discounts[1];
                } else if (amount > 4) {
                    discount = discounts[0];
                }

                lastPrice -= (lastPrice * discount) / 10000; // 75% of the value
            } else {
                require(
                    apeLastBox[apeId] + 5 minutes > block.timestamp,
                    "OpenBox: Re open time elapsed"
                );

                if (apeOpenCount[apeId] > 0) {
                    lastPrice = lastPrice * 2; // 2X the price
                } else {
                    lastPrice = (lastPrice * 3000) / 2000; // 3/2 of the price
                    apeOpenCount[apeId]++;
                }
            }
        } else {
            apeOpenCount[apeId] = 0;
        }

        if (boxType > 0) {
            uint256 discount = 0;

            if (amount > 10) {
                discount = discounts[1];
            } else if (amount > 4) {
                discount = discounts[0];
            }

            lastPrice -= (lastPrice * discount) / 10000; // 75% of the value

            require(
                msg.value >= lastPrice * amount,
                "OpenBox: Wrong ETH value"
            );
        } else {
            if (
                !hasPower || apeLastBox[apeId] + powerCooldown > block.timestamp
            ) {
                require(
                    apeLastBox[apeId] + 5 minutes > block.timestamp,
                    "OpenBox: Re open time elapsed"
                );

                if (apeOpenCount[apeId] > 0) {
                    lastPrice = lastPrice * 2; // 2X the price
                } else {
                    lastPrice = (lastPrice * 3000) / 2000; // 3/2 of the price
                    apeOpenCount[apeId]++;
                }
            } else {
                apeOpenCount[apeId] = 0;
            }

            if (!freeSpinUsed[apeId]) {
                lastPrice = 0;
            }

            methContract.transferFrom(msg.sender, treasury, lastPrice * amount);
        }

        (uint256[] memory prizes, bool hasExtra) = randomizerContract.getRandom(
            randomSeed,
            amount
        );
        uint256[] memory prizesAmounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            prizesAmounts[i] = 1;
        }

        traitsContract.mintBatch(msg.sender, prizes, prizesAmounts);

        emit BoxOpened(boxId, boxType, apeId, amount, prizes);
    }

    function getPrice(uint256 boxId) public view returns (uint256 price) {
        LootBox memory currentBox = boxInfo[boxId];

        uint256 lastOpen = lastBoxOpen[boxId];

        price = currentBox.currentPrice;

        if (block.timestamp - lastOpen < priceTimeFrame) {
            uint256 lastIncrease = lastBoxIncrease[boxId];
            if (block.timestamp - lastIncrease < priceTimeFrame) {
                price += ((price * increasePercentage) / 10000);
            }
        } else {
            price -= ((price * decreasePercentage) / 10000);
        }

        if (price > currentBox.maxPrice) {
            price = currentBox.maxPrice;
        } else if (price < currentBox.minPrice) {
            price = currentBox.minPrice;
        }

        return price;
    }

    function giveFreeSpin(uint256 apeId) external onlyOwner {
        freeSpinUsed[apeId] = false;
    }

    function setIsCreator(address operator, bool status) external onlyOwner {
        isBoxCreator[operator] = status;
    }

    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function setTreasuryAddress(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setDiscounts(uint256 _5Discount, uint256 _11Discount)
        external
        onlyOwner
    {
        discounts[0] = _5Discount;
        discounts[1] = _11Discount;
    }

    function setContractAddresses(
        address _apesAddress,
        address _traitsAddress,
        address _randomizerAddress,
        address _methAddress
    ) external onlyOwner {
        apesContract = IApes(_apesAddress);
        traitsContract = ITraits(_traitsAddress);
        randomizerContract = IRandomizer(_randomizerAddress);
        methContract = IERC20(_methAddress);
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
