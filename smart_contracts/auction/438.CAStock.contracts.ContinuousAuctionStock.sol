// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.4;

import "./ConvertLib.sol";
import "./Queue.sol";
import "./DoublySortedLinkedList.sol";


struct BuyRequest {
    uint256 price;
    uint256 stock;
    uint256 amount; // fixed value for record purpose
    uint8 status; // 1: pending, 2: abort, 3: finished
    address buyer;
}

struct SellRequest {
    uint256 price;
    uint256 stock;
    uint256 amount; // fixed value for record purpose
    uint8 status; // 1: pending, 2: abort, 3: finished
    address seller;
}

contract ContinuousAuctionStock {

    // the account address of the issuer
    address public issuer;
    
    // the number of stocks issued
    uint public count;

    // record the stock balance of each user
    mapping (address => uint) public stocks;

    mapping (address => uint) public payed;

    // buy requests
    BuyRequest[] public buyReqs;

    // sell requests
    SellRequest[] public sellReqs;

    DoublySortedLinkedList public buyPrices = new DoublySortedLinkedList();

    DoublySortedLinkedList public sellPrices = new DoublySortedLinkedList();

    uint public pricingFactor = 1 gwei;
    
    event log(string message);
    
    event logInt(uint value);
    
    event buyRequest(address buyer, uint price, uint amount, uint value);

    constructor () {
        issuer = msg.sender;
    }

    function setPricingFactor(uint factor) public returns (bool) {
        if (msg.sender == issuer && count == 0) {
            pricingFactor = factor;
            return true;
        } else {
            emit log("Cannot set the pricing factor on the flight. / You don't have the permission.");
            return false;
        }
    }

    function buy(uint price) public payable {
        address buyer = msg.sender;
        uint amount = msg.value / pricingFactor / price;
        uint unuse = msg.value / pricingFactor - price * amount;
        emit buyRequest(buyer, price, amount, msg.value);
        
        if (address(this).balance < unuse * pricingFactor) {
            emit log("not enough balance to return the unused");
            emit logInt(address(this).balance / pricingFactor);
            // this branch should not be reached normally
            // if reached, revert all the transactions
            revert();
        } else if (unuse > 0) {
            emit log("send back the unused");
            payable(buyer).transfer(unuse * pricingFactor);    
        }
        
        buyReqs.push(BuyRequest(price, amount, amount, 1, buyer));
        uint requestID = buyReqs.length - 1;
        
        // 1. if can be satisified, process directly
        if (price > sellPrices.min()) {
            uint id = sellPrices.findle(price);
            while (id != 0) {
                Queue q = sellPrices.getQ(id);
                while (!q.empty()) {
                    uint sellReqID = q.top();
                    SellRequest storage request = sellReqs[sellReqID];
                    if (request.status == 1) {
                        address payable seller = payable(request.seller);
                        uint sellPrice = request.price;
                        if (request.stock > amount) {
                            request.stock -= amount;
                            buyReqs[requestID].status = 3;
                            buyReqs[requestID].amount = 0;
                            stocks[buyer] += amount;
                            seller.transfer(sellPrice * amount * pricingFactor);
                            payable(buyer).transfer((price-sellPrice) * amount * pricingFactor);
                            return;
                        } else {
                            amount -= request.stock;
                            buyReqs[requestID].stock -= request.stock;
                            stocks[buyer] += request.stock;
                            request.status = 3;
                            seller.transfer(sellPrice * request.stock * pricingFactor);
                            payable(buyer).transfer((price-sellPrice) * request.stock * pricingFactor);
                            request.stock = 0;
                            q.dequeue();
                        }
                    }
                }
                uint prevID = sellPrices.getPrev(id);
                sellPrices.updateQ(id, q);
                id = prevID;
            }
        }
        
        // 2. else add the left amount to the queue
        uint idx = buyPrices.find(price);
        if (idx == 0) {
            // not found
            Queue newPriceQ = new Queue();
            newPriceQ.enqueue(requestID);
            buyPrices.insert(DataValue(newPriceQ, price));
            emit log("new buy request price");
        } else {
            buyPrices.insertToQueue(idx, requestID);
            emit log("add buy request to existing queue");
        }
        
    }

    function sell(uint amount, uint price) public {
        emit log("sell");
        if (msg.sender == issuer) {
            count += amount;
        }
        address seller = msg.sender;
        if (msg.sender != issuer && stocks[seller] < amount ) {
            emit log("no enough stock to sell");
            return;
        }
        
        if (seller != issuer) {
            stocks[seller] -= amount;
        }
        
        sellReqs.push(SellRequest(price, amount, amount, 1, seller));
        emit logInt(sellReqs.length);
        uint requestID = sellReqs.length - 1;
        emit logInt(requestID);

        // 1. if can be satisified, process directly
        if (price < buyPrices.max()) {
            emit log("request can be satisified");
            uint id = buyPrices.findge(price);
            while (id != 0) {
                Queue q = buyPrices.getQ(id);
                while (!q.empty()) {
                    uint buyReqID = q.top();
                    BuyRequest storage request = buyReqs[buyReqID];
                    if (request.status == 1) {
                        // address payable seller = payable(request.seller);
                        if (request.stock > amount) {
                            request.stock -= amount;
                            stocks[request.buyer] += amount;
                            sellReqs[requestID].status = 3;
                            sellReqs[requestID].stock = 0;
                            payable(seller).transfer(price * amount * pricingFactor);
                            return;
                        } else {
                            amount -= request.stock;
                            sellReqs[requestID].stock -= request.stock;
                            stocks[request.buyer] += request.stock;
                            request.status = 3;
                            payable(seller).transfer(price * request.stock * pricingFactor);
                            request.stock = 0;
                            q.dequeue();
                        }
                    }
                }
                uint nextID = sellPrices.getPrev(id);
                buyPrices.updateQ(id, q);
                id = nextID;
            }
        }
                        
        // 2. else add the left amount to the queue
        emit log("new request");
        uint idx = sellPrices.find(price);
        if (idx == 0) {
            // not found
            Queue newPriceQ = new Queue();
            newPriceQ.enqueue(requestID);
            sellPrices.insert(DataValue(newPriceQ, price));
            emit log("new sell request price");
        } else {
            sellPrices.insertToQueue(idx, requestID);
            emit log("add sell request to existing queue");
        }
    }

    function balance(address addr) public view returns (uint) {
        return addr.balance;
    }


    function withdrawBuyRequst(uint requestID) public returns (uint8) {
        require(requestID < buyReqs.length);
        
        BuyRequest storage request = buyReqs[requestID];
        address buyer = request.buyer;
        
        require(buyer == msg.sender);
        
        if (request.status == 1) {
            request.status = 2;
            // TODO: return the money back
        }
        return request.status;
    }


    function withdrawSellRequst(uint requestID) public returns (uint8) {
        require(requestID < sellReqs.length);
        
        SellRequest storage request = sellReqs[requestID];
        address seller = request.seller;
        
        require(seller == msg.sender);
        
        if (request.status == 1) {
            request.status = 2;
            stocks[seller] += request.stock;
        }
        return request.status;
    }

    function getNumBuyRequest() public view returns (uint) {
        return buyReqs.length;
    }

    function getNumSellRequest() public view returns (uint) {
        return sellReqs.length;
    }

    function getBuyRequestPrice(uint id) public view returns (uint) {
        require(id < buyReqs.length);
        return buyReqs[id].price;
    }

    function getSellRequestPrice(uint id) public view returns (uint) {
        require(id < sellReqs.length);
        return sellReqs[id].price;
    }

    function getBuyRequestStock(uint id) public view returns (uint) {
        require(id < buyReqs.length);
        return buyReqs[id].stock;
    }

    function getSellRequestStock(uint id) public view returns (uint) {
        require(id < sellReqs.length);
        return sellReqs[id].stock;
    }

    function getBuyRequestAmount(uint id) public view returns (uint) {
        require(id < buyReqs.length);
        return buyReqs[id].amount;
    }

    function getSellRequestAmount(uint id) public view returns (uint) {
        require(id < sellReqs.length);
        return sellReqs[id].amount;
    }

    function getBuyRequestStatus(uint id) public view returns (uint) {
        require(id < buyReqs.length);
        return buyReqs[id].status;
    }

    function getSellRequestStatus(uint id) public view returns (uint) {
        require(id < sellReqs.length);
        return sellReqs[id].status;
    }

    function getBuyRequestBuyer(uint id) public view returns (address) {
        require(id < buyReqs.length);
        return buyReqs[id].buyer;
    }

    function getSellRequestSeller(uint id) public view returns (address) {
        require(id < sellReqs.length);
        return sellReqs[id].seller;
    }
}