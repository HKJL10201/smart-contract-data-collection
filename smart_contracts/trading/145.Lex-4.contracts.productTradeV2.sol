/*
we still have the problem with what is inside the package

write the code as if you have a workin oracle
    -> you still have to implement that the racle changes the variable
    -> when we call the oracle, make sure that we check if the item was already received or if the deal has ended; we can also check that when storing the transaction in the queue
    -> the oracle "picks up" the transaction by a Keeper or by being called by a function we control. The point is that we control the amount of API calls per minute (later per seconds)
    -> we need to store the seller's delivery choice to know which API to use. This could be one prerequirement before you are able to sell on our platform
    -> what do we do if the API doesn't work? probably the best is to froze that transaction and check them later when the API works. No lost, just longer waiting period to be paid out

create a queue which will work as a load balancer 
    //why do we even need it? Because, we can only make a few API calls per minute
    //when should it be initialized? NOt like this, storing it for historic reference. For true exaample, look bellow ::: Inside payOut(), we call the function, which will save the transaction in the queue and then will be picked up by the oracle
    //we can also minimize the API calls by storing the state in the Product's struct and only make API calls in one function
    //we can also have differrent queues for different API calls
    //maybe the queue should be initialized when the user buys the item and is picked up by the oracle. If it's not delivered, put it back in the line. 
        -> Should we check it only after the deadline has ended?  Maybe we should initialize the check to be 2 weeks and then we have the ability to change it based on the previous deliveries. Or eventually when there will be a lot of transactions, the queue will be so long we won't need this witing period. We will deprecated this function when the queue will be long enough. 
        -> We don't need to store timestamp in the struct, use it in a mapping inside the queue contract. Also we don't need to store the id inside the struct, just use the number generated in buyProduct()
        -> the purpose of this is to shorten the waiting time. If the transaction is stored in the queue, when you want to payOut(), you could wait for a long time. Bad UX
        -> do we even need to store in in a special "waitingTime queue"? We store it in a queue and if 1 week (or maybe more) hasn't past from making a purchase we skip it and don't call the API. But this means we have Transactions we won't even check. Is this optimized?
        -> the API() and checkWaitingPeriod() can be called by us and not the Keeper. We should strive for full decentralization, but in the begining this probably wouldn't be sustainable. 
        -> we could use Protectors when calling both of the functions mentioned above
        -> it's better if we check the waiting period inside of function that calls the API. Why?
            1) when we won't need the waiting period anymore, we will only change the function thaat calls the api
            2) we won't have an unused array as a variable
            3) we won't have to deal with moving all elements from waitingPeriod to queue, when we stop the waiting period
    //what do we store in the queue? Probably the struct's id, however, currently we don't store the id inside the struct
    //if only we can call function that calls API, we don't need load balancer. However, we will need it if we want to fully decentralize our service
    -> make sure if it's the same deal or maybe caller, skip it. 
    -> make sure the transactions are time based (seconds)
    -> what to do in spikes of demand?

right now, we don't implement this,        |->  you still haven't implemented the seller's depozit when the client buys an item - do we even need it? They won't be incentivized to work honestly 
but we should have some slashing mehanism  |->  also, do we let seller to define it's own depozit (they will depozit as little as they could - whta this means for the game theory, therefore, the depozit wouldn't be such a burden)

when and what do we charge/take commission?

we also have to display all the items bought/sold

the deadline shouldn't be more than a month in any case

maybe the smart contract should be optimized for where are the seller and the buyer from

somehow, we need to make sure that the api that the seller provides is correct
*/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract TradeV2 {

    struct Product{
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
        //uint2 buyerApproves;
        //storing if the item was delivered
        bool delivered;
    }

    /// @notice Using against re-entrancy
    uint2 internal locked = 1;

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
    mapping(address => uint256) internal buyersAccount;

    /// @notice Store the seller's eth balance
    mapping(address => uint256) internal sellersAccount;

    /// @notice A unique identifier of the agreement.
    mapping(uint256 => Product) public exactProduct;

    /// @notice Storing the id's of the products that the buyer has bought
    mapping(address => uint[]) internal buyerProducts;

    /// @notice Storing the id's of the products of the same seller's address
    mapping(address => uint[]) internal sellerProducts;

    /// @notice emitting an event when a product is created
    event ProductInfo(
        uint256 productPrice,
        address productSeller,
        address productBuyer,
        uint256 productDeadline,
        bool productDealEnded,
        bool productDelivered
    );

    /// @notice emitting an event fo notifying the user
    event NotifyUser(string message);

    /// @notice Buying a product
    function buyProduct(address payable _seller, uint256 _productsPrice, uint256 _deadlinePeriod) external payable {
        //enough eth must be sent
        require(msg.value == _productsPrice, "You haven't sent enough ether");
        //check that the seller has enough funds
        //require(sellersAccount[_seller] >= _productsPrice, "Not enough funds from the seller");
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
        //storing the deadline till which the product must be received
        if(_deadlinePeriod == 0){
            newProduct.deadline = block.timestamp + 2419200;
        } else {
            newProduct.deadline = block.timestamp + _deadlinePeriod;
        }
        //initializing the variable that checks if the deal has ended to false
        newProduct.dealEnded = false;
        //initializing ticking status to 1 which means No, 2 means Yes
        //newProduct.buyerApproves = 1;
        //setting to not delivered as default
        newProduct.delivered = false;
        //storing the ids of the products and connecting them to msg.sender's address so we can display them to the frontend
        buyerProducts[msg.sender].push(numProduct);
        //storing the ids of the products and connecting them to _seller's address so we can display them to the frontend
        sellerProducts[_seller].push(numProduct);
        //emitting an event
        emit ProductInfo(
            newProduct.price, 
            newProduct.seller,
            newProduct.buyer, 
            newProduct.deadline,
            newProduct.dealEnded,
            newProduct.delivered
        );
    }

    /// @notice The buyer withdrawing the money that belongs to his/her address
    function withdrawAsTheBuyer() external payable noReentrant {
        //checking if there are any funds left to withdraw by msg.sender
        require(buyersAccount[msg.sender] > 0, "There aren't any funds to withdraw");	
        //send the funds to msg.sender  	  
        (bool sent, ) = msg.sender.call{value: buyersAccount[msg.sender]}("");
        //if the transaction fails, revert everything
        require(sent, "Failed to send Ether");
        //modify the mapping to 0
        buyersAccount[msg.sender] = 0;
        //emit an event
        emit NotifyUser("Withdrawal has been transfered");
    }

    /// @notice The seller withdrawing the money that belongs to his/her address
    function withdrawAsTheSeller() external payable noReentrant {
        //checking if there are any funds left to withdraw by msg.sender
        require(sellersAccount[msg.sender] > 0, "There aren't any funds to withdraw");	  
        //send the funds to msg.sender 
        (bool sent, ) = msg.sender.call{value: sellersAccount[msg.sender]}("");
        //if the transaction fails, revert everything
        require(sent, "Failed to send Ether");
        //modify the mapping to 0
        sellersAccount[msg.sender] = 0;
        //emit an event
        emit NotifyUser("Withdrawal has been transfered");
    }
/*
    /// @notice The buyer sets the status to Yes
    function buyerTicksYes(uint256 _id) external {
        //check if the deadline + 1 week hasn't passed
        require(exactProduct[_id].deadline >= block.timestamp, "The changing status deadline has expired");
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
*/
    /// @notice The seller forces end of the deal before the deadline, when both parties ticked Yes
    function forcedEndDeal(uint256 _id) external {
        //only the seller can call this function
        require(exactProduct[_id].seller == msg.sender, "You aren't the seller of this product");
        //check if the deadline + 1 week hasn't pass
        require(exactProduct[_id].deadline + 604800 >= block.timestamp, "The deadline has expired");
        //check if the deal has ended
        require(exactProduct[_id].dealEnded == false, "The deal has already ended");
        //check if seller's and buyer's statuses are yes or if the item was received
        if (exactProduct[_id].buyerApproves == 2 || exactProduct[_id].delivered == true){
            //transfer price of the product to the seller
            sellersAccount[exactProduct[_id].seller] += exactProduct[_id].price;
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
        /*
        //if buyer's status is No and seller's is Yes
        if (exactProduct[_id].buyerApproves == 1){
            //burn the eth
            totalEtherBurnt += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        //if both statuses are Yes
        } else if (exactProduct[_id].buyerApproves == 2){
            //transfer price of the product to the seller
            sellersAccount[exactProduct[_id].seller] += exactProduct[_id].price;
            //increase the eth used 
            totalEtherTraded += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        }
        */
        //if it wasn't delivered
        if (exactProduct[_id].delivered == false){
            //burn the eth
            totalEtherBurnt += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        //if both statuses are Yes
        } else {
            //transfer price of the product to the seller
            sellersAccount[exactProduct[_id].seller] += exactProduct[_id].price;
            //increase the eth used 
            totalEtherTraded += exactProduct[_id].price;
            //end the deal for the product
            exactProduct[_id].dealEnded = true;
        }
    }

    /// @notice Fill up th seller's balance
    function fillUpBalance() external payable {
        sellersAccount[msg.sender] += msg.value;
    } 

    /// @notice Return the withdrawal amount of the agreement's signee
    function getWithdrawalBuyer() external view returns(uint256){
        return buyersAccount[msg.sender];
    }

    /// @notice Return the withdrawal amount of the agreement's receiver
    function getWithdrawalSeller() external view returns(uint256){
        return sellersAccount[msg.sender];
    }

    /// @notice Return the ids that the buyer has bought it
    function showBuyerProducts() external view returns(uint[] memory){
        return buyerProducts[msg.sender];
    }

    /// @notice Return the ids that the seller has bought it
    function showSellerProducts() external view returns(uint[] memory){
        return sellerProducts[msg.sender];
    }

}