// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Contract.sol";
import "./ERC721Contract.sol";

contract exAuctionContract {
    
    ERC20Contract private _erc20;
    ERC721Contract private _erc721;
    uint currentTime;
    uint maxPrice;
    address creator;
    address finalBidder;

    constructor(address erc20, address erc721) { // 토큰 instance 설정
        _erc20 = ERC20Contract(erc20);
        _erc721 = ERC721Contract(erc721);
    }

    // NFT별 가격을 저장할 mapping
    mapping(uint256 => uint256) private _tokenPrice;


    function enrollNFT(uint256 tokenId, uint price) public { // NFT 판매 등록 함수
        //currentTime = NFT 등록 시각 = 경매 시작시각
        currentTime = block.timestamp;
        maxPrice = price;
        require( // 실제 토큰소유자가 호출했는지, 권한 위임(별개)했는지 체크
            _erc721.ownerOf(tokenId) == msg.sender &&
            _erc721.getApproved(tokenId) == address(this),
            "TestSeller: Authentication error"
        );

        // 가격 저장
        _tokenPrice[tokenId] = price;
        creator = msg.sender;
    }

    function auctionNFT(uint256 tokenId, uint _price) public { // 경매 참여자가 부른 NFT 가격을 받아오는 함수
        require( // 경매 지속시간 1분을 넘었는지 체크
            currentTime + 1 minutes > block.timestamp,
        "You cannot buy LNFT : overtime"
        );

        require( // 참여자가 부른 가격이 max보다 낮은지 체크
            _price >= maxPrice,
        "You cannot buy LNFT :The price is low"
        );

        // 위 조건을 모두 만족했다면, maxPrice 및 finalBidder 업데이트
        maxPrice = _price;
        finalBidder = msg.sender;
    }

    function purchaseNFT(uint256 tokenId) public { // NFT 구매 함수
            require( // 경매 시간이 지났는지 체크 (경매가 끝나기 전까지 거래가 이루어지면 안 됨)
                currentTime + 1 minutes < block.timestamp,
             "Auction is proceeding"
             );

             _tokenPrice[tokenId] = maxPrice;

            _erc20.transferFrom(finalBidder, creator, _tokenPrice[tokenId]);  // erc20:  구매자 -price-> 판매자 
            _erc721.transferFrom(creator, finalBidder, tokenId);              // erc721: 판매자 -token-> 구매자 
        }
    
    function getNFTPrice(uint256 tokenId) public view returns (uint256) { // NFT 가격 확인 함수
        return _tokenPrice[tokenId];
    }

}



