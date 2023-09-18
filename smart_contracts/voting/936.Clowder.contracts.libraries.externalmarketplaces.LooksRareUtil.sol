// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

library LooksRareUtil {
    // rinkeby
    address internal constant EXCHANGE =
        0x1AA777972073Ff66DCFDeD85749bDD555C0665dA;
    address internal constant TRANSFER_MANAGER_ERC721 =
        0x3f65A762F15D01809cDC6B43d8849fF24949c86a;
    address internal constant STRATEGY_STANDARD_SALE =
        0x732319A3590E4fA838C111826f9584a9A2fDEa1a;
    bytes32 internal constant DOMAIN_SEPARATOR = 
        0x6a8c50eacf3837f71a91496bc31832bb7e76c97cd16ce5830f970949edc565e5;

    // mainnet
    // address public constant EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    // bytes32 internal constant DOMAIN_SEPARATOR = 
    //     0xad4d53a9c11a3edbe96e78e969291ab5248faeb3b8d4552c21e6bc72edb8cab3;
    // ...

    function initializationAndPermissions(address user, address erc721address)
        public
    {
        IERC721 erc721 = IERC721(erc721address);
        if (!erc721.isApprovedForAll(user, TRANSFER_MANAGER_ERC721)) {
            erc721.setApprovalForAll(TRANSFER_MANAGER_ERC721, true);
        }
    }

    function buildAndGetMarketplaceOrderHash(
        address seller,
        address collection,
        uint256 tokenId,
        uint256 listPrice, // to be paid by buyer, the amount the seller receives is affected by fees
        uint256 expiration,
        uint256 feesFraction, // (royalties + protocol fee fraction) out of 10_000
        address paymentToken,
        uint256 nonce
    )
        public
        view
        returns (
            bytes32 finalOrderHash,
            MakerOrder memory order
        )
    {
        order = MakerOrder({
          isOrderAsk: true,
          signer: seller,
          collection: collection,
          price: listPrice,
          tokenId: tokenId,
          amount: 1, // we only support ERC721 for now
          strategy: STRATEGY_STANDARD_SALE,
          currency: paymentToken,
          nonce: nonce,
          startTime: block.timestamp,
          endTime: expiration,
          minPercentageToAsk: 10_000 - feesFraction,
          params: "",

          v: 0,
          r: 0,
          s: 0
        });
        finalOrderHash = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hash(order));
    }

    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH =
        0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hash(MakerOrder memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}
