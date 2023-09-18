// /https://github.com/BeefLedger/dealrooms/blob/master/ethereum/contracts/DealRoom.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import"./ERC20Token.sol";
import "./NFTtoken.sol";

contract NFTTrade {
    //address buyer;
    //address seller;
    address creator;
    //trade[] public trades;
    uint256 tokenId;
    ERC20Token erc20;
    NFTtoken erc721;

    constructor (ERC20Token _erc20, NFTtoken _erc721) {
        erc20 = _erc20;
        erc721 = _erc721;
       //seller = _erc721.getOwner();
        //creator = _erc721.getCreator();
        //tokenId = _tokenId
    }
    /*
    struct trade {
        ERC20Token erc20;
        NFTtoken erc721;
    }

    function makeTrade(ERC20Token _erc20, NFTToken _erc721) public {
        trades.push(trade({
            erc20:_erc20,
            erc721:_erc721
        }));
        
    }
    */
    function transferNFT(address from, address to, uint256 _tokenId)  public returns (bool){
        tokenId = _tokenId;
        erc721.transferFrom(from, to, tokenId);
        //erc20.transferFrom(to, creator, 10);
        //erc20.transferFrom(to, from, 10);
    }
}