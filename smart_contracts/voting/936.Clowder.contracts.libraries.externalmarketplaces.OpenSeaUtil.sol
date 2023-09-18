// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface OpenSea {
    // mapping(address => uint256) public nonces;
    function nonces(address user) external view returns (uint256);
}

interface OpenSeaOwnableDelegateProxy {}

interface OpenSeaProxyRegistry {
    // mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
    function proxies(address user)
        external
        view
        returns (OpenSeaOwnableDelegateProxy);

    function registerProxy() external returns (OpenSeaOwnableDelegateProxy);
}

library OpenSeaUtil {
    // mainnet
    // OpenSea public constant openSea =
    //     OpenSea(0x7f268357A8c2552623316e2562D90e642bB538E5);
    // address public constant WyvernTokenTransferProxy = 0xe5c783ee536cf5e63e792988335c4255169be4e1;
    // bytes32 internal constant OPENSEA_DOMAIN_SEPARATOR =
    //     0x72982d92449bfb3d338412ce4738761aff47fb975ceb17a1bc3712ec716a5a68;
    // bytes32 internal constant _OPENSEA_ORDER_TYPEHASH =
    //     0xdba08a88a748f356e8faf8578488343eab21b1741728779c9dcfdc782bc800f8;
    // address internal constant openSeaFeeRecipient =
    //     0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
    // address internal constant openSeaMerkleValidator =
    //     0xbaf2127b49fc93cbca6269fade0f7f31df4c88a7;
    // address public constant WyvernProxyRegistry =
    // 0xa5409ec958c83c3f309868babaca7c86dcb077c1;

    // rinkeby
    OpenSea public constant openSea =
        OpenSea(0xdD54D660178B28f6033a953b0E55073cFA7e3744);
    OpenSeaProxyRegistry public constant wyvernProxyRegistry =
        OpenSeaProxyRegistry(0x1E525EEAF261cA41b809884CBDE9DD9E1619573A);
    address public constant WyvernTokenTransferProxy =
        0xCdC9188485316BF6FA416d02B4F680227c50b89e;
    bytes32 internal constant OPENSEA_DOMAIN_SEPARATOR =
        0xd38471a54d114ee69fbb07d1769a0bbecd4f429ddf5932c7098093908e24bd9d;
    bytes32 internal constant _OPENSEA_ORDER_TYPEHASH =
        0xdba08a88a748f356e8faf8578488343eab21b1741728779c9dcfdc782bc800f8;
    address internal constant openSeaFeeRecipient =
        0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
    address internal constant openSeaMerkleValidator =
        0x45B594792a5CDc008D0dE1C1d69FAA3D16B3DDc1;

    enum FeeMethod {
        ProtocolFee,
        SplitFee
    }

    /* An order on the exchange. */
    struct OpenSeaOrder {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Maker relayer fee of the order, unused for taker order. */
        uint makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint takerRelayerFee;
        /* Maker protocol fee of the order, unused for taker order. */
        uint makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint takerProtocolFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Fee method (protocol token or split fee). */
        FeeMethod feeMethod;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes calldata2; // changed 'calldata' name because of compilation error
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint extra;
        /* Listing timestamp. */
        uint listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint salt;
        /* NOTE: uint nonce is an additional component of the order but is read from storage */
    }

    function hashOpenSeaOrder(OpenSeaOrder memory order, uint nonce)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint size = 800;
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes32(index, _OPENSEA_ORDER_TYPEHASH);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.maker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.target);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.calldata2)
        );
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.replacementPattern)
        );
        index = ArrayUtils.unsafeWriteAddressWord(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.staticExtradata)
        );
        index = ArrayUtils.unsafeWriteAddressWord(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        index = ArrayUtils.unsafeWriteUint(index, nonce);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    function getOpenSeaAskOrderHash(OpenSeaOrder memory order)
        internal
        view
        returns (
            bytes32 finalOrderHash,
            bytes32 openSeaParamsOrderWithNonceHash
        )
    {
        openSeaParamsOrderWithNonceHash = hashOpenSeaOrder(
            order,
            openSea.nonces(order.maker)
        );
        finalOrderHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                OPENSEA_DOMAIN_SEPARATOR,
                openSeaParamsOrderWithNonceHash
            )
        );
    }

    function initializationAndPermissions(
        address user, 
        address erc721address, 
        address WETH
    ) public {
        // OpenSea initialization and permissions

        // Approving OpenSea to move the item (if not approved already) and WETH (yes, OpenSea requires this for the way it works)
        // initialize opensea proxy (check opensea-js)
        OpenSeaOwnableDelegateProxy myProxy = OpenSeaUtil
            .wyvernProxyRegistry
            .proxies(user);

        if (address(myProxy) == address(0)) {
            myProxy = OpenSeaUtil.wyvernProxyRegistry.registerProxy();
        }

        IERC721 erc721 = IERC721(erc721address);
        if (!erc721.isApprovedForAll(user, address(myProxy))) {
            erc721.setApprovalForAll(address(myProxy), true);
        }

        IERC20 erc20 = IERC20(WETH);
        if (
            erc20.allowance(
                user,
                OpenSeaUtil.WyvernTokenTransferProxy
            ) < type(uint256).max
        ) {
            erc20.approve(
                OpenSeaUtil.WyvernTokenTransferProxy,
                type(uint256).max
            );
        }
    }

    function buildAndGetOpenSeaOrderHash(
        address seller,
        address collection,
        uint256 tokenId,
        uint256 listPrice, // to be paid by buyer, the amount the seller receives is affected by feesFraction
        uint256 expiration,
        uint256 feesFraction, // (royalties + protocol fee fraction) out of 10_000
        address paymentToken
    )
        public
        view
        returns (
            bytes32 finalOrderHash,
            bytes32 paramsOrderHash,
            OpenSeaOrder memory order
        )
    {
        order = OpenSeaUtil.OpenSeaOrder({
            exchange: address(openSea),
            maker: seller,
            taker: address(0),
            makerRelayerFee: feesFraction,
            takerRelayerFee: 0,
            makerProtocolFee: 0,
            takerProtocolFee: 0,
            feeMethod: FeeMethod.SplitFee,
            feeRecipient: openSeaFeeRecipient,
            side: SaleKindInterface.Side.Sell,
            saleKind: SaleKindInterface.SaleKind.FixedPrice,
            target: openSeaMerkleValidator,
            howToCall: AuthenticatedProxy.HowToCall.DelegateCall,
            staticTarget: address(0),
            staticExtradata: "",
            paymentToken: paymentToken,
            basePrice: listPrice,
            extra: 0,
            calldata2: bytes.concat(
                hex"fb16a595000000000000000000000000",
                abi.encodePacked(seller),
                hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                abi.encodePacked(collection),
                abi.encodePacked(tokenId),
                hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000"
            ),
            replacementPattern: hex"000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            listingTime: block.timestamp,
            expirationTime: expiration,
            salt: block.timestamp
        });
        (finalOrderHash, paramsOrderHash) = getOpenSeaAskOrderHash(order);
    }
}

library ArrayUtils {
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) internal pure {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] =
                    ((mask[i] ^ 0xff) & array[i]) |
                    (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(a) == keccak256(b);
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
        internal
        pure
        returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal
        pure
        returns (uint)
    {
        uint conv = uint(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteAddressWord(uint index, address source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint8Word(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write bytes32 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteBytes32(uint index, bytes32 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }
}

//// starts more OPENSEA stuff

library SaleKindInterface {
    /**
     * Side: buy or sell.
     */
    enum Side {
        Buy,
        Sell
    }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind {
        FixedPrice,
        DutchAuction
    }
}

library AuthenticatedProxy {
    enum HowToCall {
        Call,
        DelegateCall
    }
}

//// ends OPENSEA stuff
