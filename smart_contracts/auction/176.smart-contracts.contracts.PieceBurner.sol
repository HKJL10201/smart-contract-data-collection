// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IPiece.sol";
import "./interfaces/IMillionPieces.sol";
import "./interfaces/IPieceBurner.sol";


contract PieceBurner is IPieceBurner {
  using SafeMath for uint256;
  using SafeERC20 for IPiece;

  uint256 public constant BATCH_SWAP_LIMIT = 25;
  uint256 public constant PIECE_FOR_ONE_NFT = 1 ether;

  IPiece public piece;
  IMillionPieces public millionPieces;

  event NewSingleSwap(address initiator, address receiver, uint256 tokenId);
  event NewBatchSwap(address initiator, address receiver, uint256[] tokenIds);

  constructor (address _piece, address _millionPieces) public {
    require(_piece != address(0), "PieceBurner: Piece address can not be empty!");
    require(_millionPieces != address(0), "PieceBurner: NFT address can not be empty!");

    piece = IPiece(_piece);
    millionPieces = IMillionPieces(_millionPieces);
  }

  //  --------------------
  //  PUBLIC
  //  --------------------

  function swap(uint256 tokenId, address receiver) public override {
    _swap(tokenId, msg.sender, receiver);

    emit NewSingleSwap(msg.sender, receiver, tokenId);
  }

  function batchSwap(uint256[] memory tokenIds, address receiver) public override {
    _batchSwap(tokenIds, msg.sender, receiver);

    emit NewBatchSwap(msg.sender, receiver, tokenIds);
  }

  //  --------------------
  //  INTERNAL
  //  --------------------

  function _swap(uint256 tokenId, address initiator, address receiver) internal {
    require(millionPieces.isValidArtworkSegment(tokenId), "swap: Invalid token ID");

    // Receive PIECE token from initiator address
    piece.safeTransferFrom(initiator, address(this), PIECE_FOR_ONE_NFT);

    // Mint predefined token id and send to receiver address
    _mintNft(receiver, tokenId);

    // Burn PIECE token
    piece.burn(PIECE_FOR_ONE_NFT);
  }

  function _batchSwap(uint256[] memory tokenIds, address initiator, address receiver) internal {
    uint256 requiredPiece = tokenIds.length;
    require(requiredPiece > 0 && requiredPiece <= BATCH_SWAP_LIMIT, "_batchSwap: Tokens amount should be less then swap limit!");

    // Receive PIECE token from initiator address
    piece.safeTransferFrom(initiator, address(this), requiredPiece.mul(PIECE_FOR_ONE_NFT));

    // Mint predefined tokenIds and send to receiver address
    for (uint256 i = 0; i < requiredPiece; i++) {
      _mintNft(receiver, tokenIds[i]);
    }

    // Burn PIECE tokens
    piece.burn(requiredPiece.mul(PIECE_FOR_ONE_NFT));
  }

  /**
    * @notice Mint simple segment.
    */
  function _mintNft(address receiver, uint256 tokenId) private {
    millionPieces.mintTo(receiver, tokenId);
  }
}