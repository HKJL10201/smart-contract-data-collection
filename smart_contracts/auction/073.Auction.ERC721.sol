pragma solidity ^0.8.9;
//ERC-721 Marketplace and auction
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721  is IERC721{

    uint256 setPrice;
    uint256 tokenId;

    string public name;
    string public symbol;

    address owner = msg.sender;

    mapping(address => uint256)balance;
    mapping(uint => address)Owner;
    mapping(uint => address)_tokenApprovals;
    mapping(address=>mapping(address=>bool)) operatorApprovals;
    mapping(uint256 => uint256) private _sellPriceLead;
    mapping(uint256 => Auction) private ERC721Auction;
    mapping(uint256 => uint256) private currentTime;
    mapping(uint256 => address) private leadBidder;

    struct Auction{
        address  seller;
        uint256  time;
        uint256  basePrice;
        uint256  bidPrice;

    }

    constructor(string memory _name,string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address Account)public view returns(uint){
        return balance[Account];
    }

    function ownerOf(uint256 tokenId)public view returns(address){
        return Owner[tokenId];
    }

    function safeTransferFrom(address from, address to,uint256 tokenId, bytes calldata data )public {
        require(from == address(0),"from should be address zero");
        require(to!= address(0),"to shoud not be address zero");
        transferFrom(from,to,tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId)public {
        require(from == address(0),"from should be address zero");
        transferFrom(from,to,tokenId);
    }

    function transferFrom(address from,address to,uint256 tokenId)public {
        require(to != address(0)," you cannot send to address zero");
        balance[from] -= tokenId;
        balance[to] += tokenId;
        emit Transfer(from,to,tokenId);

    }

    function approve(address to, uint256 tokenId)public {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId)public view returns(address){ 
        require(Owner[tokenId] != address(0),"token doesn't exit");
		return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)public view returns(bool){
        return operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved)public {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender,operator,approved);
    }

    function supportsInterface(bytes4 interfaceID)public view returns(bool){

    }

    function mint(address owner,uint256 tokenId)public returns(bool){
        require (!_exists(tokenId),"This token is already minted");
        require(owner == msg.sender,"only owner can mint");
        balance[owner] += tokenId;
        Owner[tokenId] = owner;
    }

    function burn(uint256 tokenId)public {
        require(!_exists(tokenId),"This token Id is not exist");
        balance[owner] -= tokenId;
    }

     function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return Owner[tokenId] != address(0);
    }

    // function startAuction(address owner,uint256 tokenId)public {
    //     require(!_exists(tokenId),"This not exists");
    //     require(ownerOf(tokenId)==owner,"You dont owe this token");
    // }

     function setForSale(uint256 tokenId, uint256 setPrice)public {
        // require(!_exists(tokenId),"This token ID is not exist so you cannot put for sale");
        require(owner == msg.sender,"Only owner can set NFT for sale");
        address owner = ownerOf(tokenId);

        emit Approval(msg.sender, address(this), tokenId);
    }

    function buy(uint256 tokenId)public payable{
        require(msg.value >= setPrice,"The price should be high enough");
        require(ownerOf(tokenId) == owner,"you are not the owner");
        // require(!_exists(tokenId),"This token ID is not exist");
        require(msg.value <= 1 ether,"it should be 1 ether or more");
        require(getApproved(tokenId) == address(this),"The Token is not Approved by the contract owner");
        address buyer = msg.sender;
        transferFrom(ownerOf(tokenId),buyer,tokenId);

    }

    function startAuction(address owner,uint256 tokenId, uint256 setPrice, uint time)public returns(bool){
        require(_exists(tokenId),"There no token of this ID");
        require(ownerOf(tokenId) == owner,"Only owner can");
        require(setPrice >= 1 ether,"set Price is very low");
        _sellPriceLead[tokenId] = setPrice;
        ERC721Auction[tokenId].seller = msg.sender;
        ERC721Auction[tokenId].time = time;
        ERC721Auction[tokenId].basePrice = setPrice;
        ERC721Auction[tokenId].bidPrice = setPrice;
        return true;
    }

    function Bid(uint256 tokenId, uint256 your_price) public payable {
        if(currentTime[tokenId] == 0){
            currentTime[tokenId] = block.timestamp;
        }
        // require(!_exists(tokenId),"This token ID is not exist");
        require(ERC721Auction[tokenId].seller != address(0),"This token is not in Auction");
        require(msg.value > ERC721Auction[tokenId].bidPrice,"Your bid should be greater than previous bid");
        require(currentTime[tokenId] != 0 &&  block.timestamp > currentTime[tokenId] && block.timestamp <= currentTime[tokenId] + ERC721Auction[tokenId].time,"Time is owner");

        if(leadBidder[tokenId] != address(0)){
            payable(leadBidder[tokenId]).transfer(ERC721Auction[tokenId].bidPrice);
        }else{
            revert("Invalid token");
        }

    }

    function claimNfts(address from, uint256 tokenId)public{
        require(!_exists(tokenId),"This Token ID not exist");
        require(block.timestamp >= ERC721Auction[tokenId].time,"The Auction is not finiesh yet");
        require(msg.sender == leadBidder[tokenId],"Ooops you are not the highest bidder");
        payable (ERC721Auction[tokenId].seller).transfer(ERC721Auction[tokenId].bidPrice);
        transferFrom(ERC721Auction[tokenId].seller,msg.sender,tokenId);
    }

    fallback ()external{}

    receive()external payable{}


}