// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract IndividualSimplePaymentTangible is IERC721Receiver {
    uint256 public tokenId;
    address payable public seller;
    address payable admin;
    bool public tokenAdded;
    ERC721  nftContract;  
    // how much the item costs
    uint256 public price; 
    // the payment by the buyer
    uint256 payment;
    uint256 fee;
    bool public paid;
    
    constructor(
        uint256 _price,
        address payable _admin
    ) payable {
        require(
            _price > 0,
            "The price has to be greater than 0."
        );
        
        seller = payable(msg.sender);
        admin = _admin;
        price = _price;
    }

    modifier onlySeller() {
        require(
            msg.sender == seller,
            "Unauthorized"
        );
        _;
    }
    
    event PaymentMade(address payer, uint256 amount);
    
    function pay() external payable {
        require(
            tokenAdded == true,
            "Token not added yet"
        );
        
        require(
            msg.value == price,
            "Incorrect price."
        );
        
        require(
            paid == false,
            "Already paid"
        );
        
        payment = msg.value;

        fee = msg.value * 2 / 100;
        payment = msg.value - fee;
        
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        
        paid = true;
        
        emit PaymentMade(msg.sender, msg.value);
    }
    
    function withdraw() external onlySeller {
        require(payment != 0, "Already withdrawn");
        require(fee != 0, "Already withdrawn");

        uint256 _payment = payment;
        payment = 0;

        uint256 _fee = fee;
        fee = 0;

        admin.transfer(_fee);
        payable(msg.sender).transfer(_payment);
    }
    
    // function withdrawFee() external {
    //     require(
    //         admin == msg.sender,
    //         "Not authorized"
    //     );
        
    //     admin.transfer(fee);
    // }
    
    function abort() external onlySeller {
        require(
            paid == false,
            "Already purchased"
        );
        
        nftContract.transferFrom(address(this), seller, tokenId);
    }
    
    function onERC721Received(address, address, uint256 _tokenId, bytes memory) external virtual override returns (bytes4) {
        require(seller == tx.origin, "Unauthorized");
        require(tokenAdded == false, "Already has a token");
        
        nftContract = ERC721(msg.sender);
        tokenId = _tokenId;
        tokenAdded = true;
        return this.onERC721Received.selector;
    }

    // for testing
    function getInfo() external view returns (uint256, address, address, bool, uint256, uint256, uint256, bool) {
        return (tokenId, seller, admin, tokenAdded, price, payment, fee, paid);
    } 
}
