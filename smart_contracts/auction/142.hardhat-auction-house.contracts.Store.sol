pragma solidity ^0.7.3;
import "hardhat/console.sol";
// import "./Escrow.sol";
contract Store{
    enum ProductStatus {Open, Sold, Unsold}
    enum ProductCondition {New , Used}

    uint public productIndex;
    mapping (uint => address) productIdInStore;
    mapping (address => mapping(uint => Product)) stores;
    mapping (uint => mapping(address => Bid)) bids;
   
    struct Product{
        uint id;
        string name;
        string category;
        string  imgLink;
        string descLink;
        uint auctionStartTime;
        uint auctionEndTime;
        uint startPrice;
        address payable highestBidder;
        address payable secondHighestBidder;
        uint highestBid;
        uint secondHighestBid;
        ProductStatus status;
        ProductCondition condition;
    }    

    struct Bid{
        address payable bidder;
        uint productId;
        uint value;
        bool revealed;
    }

    constructor() public{
        productIndex = 0;
    }

    function addProductToStore(
        string memory _name,
        string memory _category,
        string memory _imgLink,
        string memory _descLink,
        uint _auctionStartTime,
        uint _auctionEndTime,
        uint _startPrice,
        uint _productCondition
    ) public{
            require(_auctionStartTime < _auctionEndTime);
            productIndex += 1;
            Product memory product = Product(
                productIndex,
                _name,
                _category,
                _imgLink,
                _descLink,
                _auctionStartTime,
                _auctionEndTime,
                _startPrice,
                address(0),
                address(0),
                0,
                0,
                ProductStatus.Open,
                ProductCondition(_productCondition)
            );
            stores[msg.sender][productIndex]=product;
            productIdInStore[productIndex] = msg.sender;
    }

    function getProduct(uint _productId) public view returns (
                uint,
                string memory, 
                string memory,
                string memory, 
                string memory,  
                uint, 
                uint,  
                uint,
                ProductStatus, 
                ProductCondition
                ){
                    //Using productIdInStore to find the store address. in stores
                    //Then, use the address and _productId to find the product
                    Product storage product = stores[productIdInStore[_productId]][_productId];
                    return (product.id,
                            product.name,
                            product.category,
                            product.imgLink,
                            product.descLink,
                            product.auctionStartTime,
                            product.auctionEndTime,
                            product.startPrice,
                            product.status,
                            product.condition
                    );
                }

    function bid(uint _productId) public payable returns (bool) {
        Product storage product = stores[productIdInStore[_productId]][_productId];
        // bytes32 _bid = keccak256(abi.encode(_amount, _secret));
        // console.log(msg.value);
        require(block.timestamp >= product.auctionStartTime, "The product has not yet started to be auctioned!");
        require(block.timestamp <= product.auctionEndTime, "The product has ended auction!");
        require(msg.value > product.startPrice,"The price you bid is lower than the start price!");
        // require(bids[_productId][msg.sender].bidder==address(0),"You bided with same token!");
        require(msg.value>=product.secondHighestBid, "You bid is less that second highest bid, we will not accept you value!");
        require(productIdInStore[productIndex]!=msg.sender,"You are the product owner, can not bid it!");
        if(product.highestBid==0){
            bids[_productId][msg.sender]=Bid(msg.sender, _productId, msg.value, false);
            product.secondHighestBid=product.startPrice;
            product.highestBid=msg.value;
            product.highestBidder=msg.sender;
        }else{
            if(msg.value>product.highestBid){
                if(product.secondHighestBid!=0){
                    product.secondHighestBidder.transfer(product.secondHighestBid);
                }
                bids[_productId][msg.sender].value=msg.value;
                product.secondHighestBid=product.highestBid;
                product.secondHighestBidder=product.highestBidder;
                product.highestBid=msg.value;
                product.highestBidder=msg.sender;
            }else if(msg.value==product.highestBid || (msg.value>product.secondHighestBid && msg.value<product.highestBid)){
                if(product.secondHighestBid!=0){
                    product.secondHighestBidder.transfer(product.secondHighestBid);
                }
                product.secondHighestBidder.transfer(product.secondHighestBid);
                bids[_productId][msg.sender].value=msg.value;
                product.secondHighestBid=msg.value;
                product.secondHighestBidder=msg.sender;
            }
        }

        // product.totalBids+=1;
        return true;
    }

    // function revealBid(uint _productId, string calldata _amount, string calldata _secret) public {
    //     console.log(block.timestamp);
    //     Product storage product = stores[productIdInStore[_productId]][_productId];
    //     require(block.timestamp >= product.auctionEndTime,"The auction is now over!");
    //     bytes32 sealedBid = keccak256(abi.encode(_amount, _secret));
        
    //     Bid memory bidInfo = bids[msg.sender][sealedBid];
    //     console.log(bytes32ToString(sealedBid));
    //     require(bidInfo.bidder != address(0), "Bidder should exist");
    //     require(bidInfo.revealed == false, "Bid should not be revealed!"); 
    //     uint refund;
    //     uint amount = stringToUint(_amount);
    //     if(bidInfo.value < amount){
    //         refund=bidInfo.value;
    //     }else{
    //           if(product.highestBidder == address(0)){
    //               product.highestBidder = msg.sender;
    //               product.highestBid = amount;
    //               product.secondHighestBid = product.startPrice;
    //               refund = bidInfo.value - amount;
    //           }else {
    //               if(amount > product.highestBid){
    //                  product.secondHighestBid=product.highestBid;
    //                  product.highestBidder.transfer(product.highestBid);
    //                  product.highestBid =amount;
    //                  product.highestBidder = msg.sender;
    //                  refund = bidInfo.value - amount;
    //               }else if(amount > product.secondHighestBid){
    //                  product.secondHighestBid = amount;
    //                  refund = bidInfo.value;
    //               }else{
    //                  refund = bidInfo.value;
    //               }
    //           }
    //     }
    //     bids[msg.sender][sealedBid].revealed = true;
    //     if(refund > 0){
    //         msg.sender.transfer(refund);
    //     }
    // }

    // function stringToUint(string memory s) private pure returns(uint){
    //     bytes memory b = bytes(s);
    //     uint result=0;
    //     for(uint i=0;i<b.length;i++){
    //         if(uint8(b[i]) >= 48 && uint8(b[i]) <=57){
    //             result = result * 10 + (uint8(b[i])-48);
    //         }
    //     }
    //     return result;
    // }

    function higheatBidderInfo(uint _productId) public view returns (address, uint, uint){
        Product memory product = stores[productIdInStore[_productId]][_productId];
        return (product.highestBidder, product.highestBid, product.secondHighestBid);
    }

    // function totalBids(uint _productId) public view returns (uint){
    //     Product memory product = stores[productIdInStore[_productId]][_productId];
    //     return product.totalBids;
    // }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function getProductNumber() public view returns(uint){
        return productIndex;
    }

    function finalizaAuction(uint _productId) public {
        Product memory product = stores[productIdInStore[_productId]][_productId];
        require(block.timestamp > product.auctionEndTime);
        require(product.status == ProductStatus.Open);
        require(product.highestBidder != msg.sender,"You are bidder, not owner!");
        require(productIdInStore[_productId] == msg.sender,"You are not owner!");
        

        if(product.secondHighestBid == 0){
            product.status = ProductStatus.Unsold;
        }else{
            product.status = ProductStatus.Sold;
            uint refund = product.highestBid - product.secondHighestBid;
            if(refund!=0){
                product.highestBidder.transfer(refund);
            }
            product.secondHighestBidder.transfer(product.secondHighestBid);
        }
        stores[productIdInStore[_productId]][_productId]=product;
    }

    // function escrowAddressForProduct(uint _productId) public view returns (address) {
    //     return productEscrow[_productId];
    // }

    // function escrowInfo(uint _productId)public view returns (address, address, address, bool, uint, uint){
    //     return Escrow(productEscrow[_productId]).escrowInfo();
    // }

    function getWinner (uint _productId) public view returns(address, uint){
        Product memory product = stores[productIdInStore[_productId]][_productId];
        require(product.highestBidder!=address(0), "No one bid it!");
        return (product.highestBidder, product.secondHighestBid);
    }
}