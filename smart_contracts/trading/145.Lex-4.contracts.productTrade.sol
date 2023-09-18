// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
    - The buyer creates a new address and sends some eth to it. Preferably, by using tornado cash or any other way to fill it with eth without any backward connections
    - The seller creates a new address for every transaction
    - The seller tells the buyer to which address send the eth
    - The buyer sends eth and seller's address to our sc

    - Can we create a system where seller rejects if msg.value of the buyer is to low? 
    Would it be better if the seller (or maybe even a buyer) initialize a struct with deadline, msg.value, identificator and closed arguments?
    Maybe deadline should be by default 4weeks. 

    buyerApproves, sellerApproves : 1 - no, 2 - yes
*/

contract TradeV1 {

    struct Product{
        //id of the product
        uint256 id;
        //price of the product
        uint256 price;
        //seller's address where the eth will go
        address seller;
        //buyer's address 
        address buyer;
        //storing product's deadline 
        uint256 deadline;
        //storing product's fullfillment status
        bool dealEnded;
        //storing buyer's ticking status
        uint256 buyerApproves;
        //storing seller's ticking status
        uint256 sellerApproves;
    }

    /// @notice Using against re-entrancy
    uint8 internal locked = 1;

    /// @notice Used to increase the id of the agreements in the "buyProduct" function
    uint256 public numProduct = 0;

    /// @notice Returning the total amount of eth that was used for buying products
    uint256 public totalEtherTraded;

    /// @notice Returning the total amount of eth that was burnt
    uint256 public totalEtherBurnt;  

    /// @notice Not allowing reentrance
    modifier noReentrant() {
        require(locked == 1, "No re-entrancy");
        locked = 2;
        _;
        locked = 1;
    }

    /// @notice Saving the eth sent for the buyer to withdraw it
    mapping(address => uint256) private withdraw_buyer;

    /// @notice Saving the eth sent for the seller to withdraw it
    mapping(address => uint256) private withdraw_seller;

    /// @notice A unique identifier of the agreement. The same as the id.
    mapping(uint256 => Product) public exactProduct;

    /// @notice Storing the id's of the products that the buyer has bought
    mapping(address => uint[]) public buyerProducts;

    /// @notice Storing the id's of the products of the same seller's address
    mapping(address => uint[]) public sellerProducts;

    /// @notice emitting an event when a product is created
    event ProductInfo(
        uint256 productId,
        uint256 productPrice,
        address productSeller,
        address productBuyer,
        uint256 productDeadline,
        bool productDealEnded
    );

    /// @notice emitting an event fo notifying the user
    event NotifyUser(string message);

    /// @notice Buying a product
    function buyProduct(address payable _seller) external payable {
        //eth must be sent
        require(msg.value > 0, "You haven't sent ether");
        //increment the number of the id
        numProduct++;
        //creating a new instance of a product
        Product storage newProduct = exactProduct[numProduct];
        //storing the id
        newProduct.id = numProduct;
        //storing the price
        newProduct.price = msg.value;
        //storing the seller's address
        newProduct.seller = _seller;
        //storing the buyer's address
        newProduct.buyer = msg.sender;
        //storing the deadline till which the product must be shipped
        newProduct.deadline = block.timestamp + 2419200;
        //initializing the variable that checks if the deal has ended to false
        newProduct.dealEnded = false;
        //initializing ticking status to 1 which means No, 2 means Yes
        newProduct.buyerApproves = 1;
        //initializing ticking status to 1 which means No, 2 means Yes
        newProduct.sellerApproves = 1;
        //storing the ids of the products and connecting them to msg.sender's address so we can display them to the frontend
        buyerProducts[msg.sender].push(numProduct);
        //storing the ids of the products and connecting them to _seller's address so we can display them to the frontend
        sellerProducts[_seller].push(numProduct);
        //emitting an event
        emit ProductInfo(
            newProduct.id, 
            newProduct.price, 
            newProduct.seller,
            newProduct.buyer, 
            newProduct.deadline,
            newProduct.dealEnded
        );
    }

    ///@notice Rejecting selling the product by the seller
    function rejectSelling(uint256 _id) external {
        //check if the product's deal has already ended
        require(exactProduct[_id].dealEnded == false, "The deal has already ended");
        //check if the seller is the correct one
        require(exactProduct[_id].seller == msg.sender, "You aren't the seller of this product");
        //return the price of the product to the buyer
        withdraw_buyer[exactProduct[_id].buyer] += exactProduct[_id].price;
        //end the deal for the product
        exactProduct[_id].dealEnded = true;
    }

    /// @notice The buyer withdrawing the money that belongs to his/her address
    function withdrawAsTheBuyer() external payable noReentrant {
        //checking if there are any funds left to withdraw by msg.sender
        require(withdraw_buyer[msg.sender] > 0, "There aren't any funds to withdraw");	
        //send the funds to msg.sender  	  
        (bool sent, ) = msg.sender.call{value: withdraw_buyer[msg.sender]}("");
        //if the transaction fails, revert everything
        require(sent, "Failed to send Ether");
        //modify the mapping to 0
        withdraw_buyer[msg.sender] = 0;
        //emit an event
        emit NotifyUser("Withdrawal has been transfered");
    }

    /// @notice The seller withdrawing the money that belongs to his/her address
    function withdrawAsTheSeller() external payable noReentrant {
        //checking if there are any funds left to withdraw by msg.sender
        require(withdraw_seller[msg.sender] > 0, "There aren't any funds to withdraw");	  
        //send the funds to msg.sender 
        (bool sent, ) = msg.sender.call{value: withdraw_seller[msg.sender]}("");
        //if the transaction fails, revert everything
        require(sent, "Failed to send Ether");
        //modify the mapping to 0
        withdraw_seller[msg.sender] = 0;
        //emit an event
        emit NotifyUser("Withdrawal has been transfered");
    }

    /// @notice The buyer sets the status to Yes
    function buyerTicksYes(uint256 _id) external {
        //check if the deadline + 1 week hasn't passed
        require(exactProduct[_id].deadline + 604800 >= block.timestamp, "The changing status deadline has expired");
        //check if the function's caller is the product's buyer
        require(exactProduct[_id].buyer == msg.sender, "You are not the product's buyer");
        //check if the function's status isn't already Yes
        require(exactProduct[_id].buyerApproves != 2, "The status is already set to Yes");
        //if the ticked status is 1, increase it by 1 (2 means Yes)
        if (exactProduct[_id].buyerApproves == 1){
            exactProduct[_id].buyerApproves += 1;
        //otherwise revert
        } else {revert();}
    }

    /// @notice The buyer sets the status to No
    function buyerTicksNo(uint256 _id) external {
        //check if the deadline + 1 week hasn't passed
        require(exactProduct[_id].deadline + 604800 >= block.timestamp, "The changing status deadline has expired");
        //check if the function's caller is the product's buyer
        require(exactProduct[_id].buyer == msg.sender, "You are not the product's buyer");
        //check if the function's status isn't already no
        require(exactProduct[_id].buyerApproves != 1, "The status is already set to No");
        //if the ticked status is 2, decrease it by 1 (1 means No)
        if (exactProduct[_id].buyerApproves == 2){
            exactProduct[_id].buyerApproves -= 1;
        //otherwise revert
        } else {revert();}
    }

    /// @notice The seller sets the status to yes
    function sellerTicksYes(uint256 _id) external {
        //check if the deadline + 1 week hasn't pass
        require(exactProduct[_id].deadline + 604800 >= block.timestamp, "The changing status deadline has expired");
        //check if the function's caller is the product's seller
        require(exactProduct[_id].seller == msg.sender, "You are not the product's seller");
        //check if the function's status isn't already yes
        require(exactProduct[_id].sellerApproves != 2, "The status is already set to Yes");
        //if the ticked status is 1, increase it by 1 (2 means yes)
        if (exactProduct[_id].sellerApproves == 1){
            exactProduct[_id].sellerApproves += 1;
        //otherwise revert
        } else {revert();}
    }

    /// @notice The seller sets the status to No
    function sellerTicksNo(uint256 _id) external {
        //check if the deadline + 1 week hasn't pass
        require(exactProduct[_id].deadline + 604800 >= block.timestamp, "The changing status deadline has expired");
        //check if the function's caller is the product's seller
        require(exactProduct[_id].seller == msg.sender, "You are not the product's seller");
        //check if the function's status isn't already no
        require(exactProduct[_id].sellerApproves != 1, "The status is already set to No");
        //if the ticked status is 2, decrease it by 1 (1 means no)
        if (exactProduct[_id].sellerApproves == 2){
            exactProduct[_id].sellerApproves -= 1;
        //otherwise revert
        } else {
            revert();
        }
    }

    /// @notice The seller forces end of the deal before the deadline, when both parties ticked Yes
    function forcedEndDeal(uint256 _id) external {
        //only the seller can call this function
        require(exactProduct[_id].seller == msg.sender, "You aren't the seller of this product");
        //check if the deadline + 1 week hasn't pass
        require(exactProduct[_id].deadline + 604800 >= block.timestamp, "The deadline has expired");
        //check if the deal has ended
        require(exactProduct[_id].dealEnded == false, "The deal has already ended");
        //check if seller's and buyer's statuses are yes
        if (exactProduct[_id].buyerApproves == 2 && exactProduct[_id].sellerApproves == 2){
            //transfer price of the product to the seller
            withdraw_seller[exactProduct[_id].seller] += exactProduct[_id].price;
            //increase the eth used 
            totalEtherTraded += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        } else {
            revert("Both seller and the buyer have to approve");
        }
    }

    /// @notice Pay out the eth that bellongs to either party (depends on the ticked status)
    function payOut(uint256 _id) external {
        //check if the msg.sender is the seller or the buyer of the product
        require(exactProduct[_id].seller == msg.sender || exactProduct[_id].buyer == msg.sender, "You aren't the seller or the buyer of this product");
        //check if the product's deal hasn't already ended
        require(exactProduct[_id].dealEnded == false, "This deal was already paid out");
        //check if the deadline + 1 week is over
        require(exactProduct[_id].deadline + 604800 >= block.timestamp, "The deadline has expired");
        //if both statuses are NO
        if (exactProduct[_id].buyerApproves == 1 && exactProduct[_id].sellerApproves == 1){
            //transfer price of the product to the buyer
            withdraw_buyer[exactProduct[_id].buyer] += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        //if buyer's status is No and seller's is Yes
        } else if (exactProduct[_id].buyerApproves == 1 && exactProduct[_id].sellerApproves == 2){
            //burn the eth
            totalEtherBurnt += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        //if buyer's status is Yes and seller's is No
        } else if (exactProduct[_id].buyerApproves == 2 && exactProduct[_id].sellerApproves == 1){
            //burn the eth
            totalEtherBurnt += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        //if both statuses are Yes
        } else if (exactProduct[_id].buyerApproves == 2 && exactProduct[_id].sellerApproves == 2){
            //transfer price of the product to the seller
            withdraw_seller[exactProduct[_id].seller] += exactProduct[_id].price;
            //increase the eth used 
            totalEtherTraded += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        }
    }

    /// @notice Return the withdrawal amount of the agreement's signee
    function getWithdrawalBuyer() external view returns(uint256){
        return withdraw_buyer[msg.sender];
    }

    /// @notice Return the withdrawal amount of the agreement's receiver
    function getWithdrawalSeller() external view returns(uint256){
        return withdraw_seller[msg.sender];
    }

}