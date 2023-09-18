pragma solidity ^0.4.18;
contract Solar {

    struct User {
        bool buying;
        address user;
        bool exists;
    }
    struct Proposal {
        uint amount;  // unit of electricity
        uint price;
        address user;
    }

    mapping(address => User) users;
    Proposal[] selling;
    Proposal[] buying;

    event PriceCalculated(uint value, uint amount, uint price);
    event showLength(uint length);
    event test(string s);

    function buy(uint amount) public payable returns (uint bought, address) {
        test("1");
        require(!users[msg.sender].exists);
        uint price = msg.value / amount;
        test("2");
        PriceCalculated(msg.value, amount, price);
        require(price * amount == msg.value);
        
        address buyer = msg.sender;
        
        if (selling.length == 0) {
            test("buying with no selling");
            buying.push(Proposal({amount:amount, price:price, user:buyer}));
            users[buyer] = User({buying: true, user:buyer, exists:true});
            return (0, 0);
        }
        
        test("buying with pending selling");
        uint lowest = 0;
        for (uint i = 0; i < selling.length; i++) {
            if (selling[i].price < selling[lowest].price) {
                lowest = i;
            }
        }
        Proposal storage best = selling[lowest];
        address seller = best.user;
        uint seller_price = best.price;
        uint seller_amount = best.amount;
        require(best.price <= price);
        if (best.amount <= amount) {
            bought = best.amount;
            delete selling[lowest];
            users[seller].exists = false;
        } else {
            bought = amount;
            best.amount -= bought;
        }
        seller.transfer(seller_price * (seller_amount + bought));
        msg.sender.transfer(msg.value - seller_price * bought);
        return (bought, seller);
    }

    function sell(uint amount) public payable returns (uint sold, address) {
        require(!users[msg.sender].exists);
        uint price = msg.value / amount;
        PriceCalculated(msg.value, amount, price);
        require(price * amount == msg.value);
        
        address seller = msg.sender;
        
        if (buying.length == 0) {
            showLength(buying.length);
            test("Inside");
            selling.push(Proposal({amount:amount, price:price, user:seller}));
            showLength(selling.length);
            users[seller] = User({buying: false, user:seller, exists:true});
            return (0, 0);
        }
        
        test("outside");
        uint highest = 0;
        for (uint i = 0; i < buying.length; i++) {
            if (buying[i].price > buying[highest].price) {
                highest = i;
            }
        }
        Proposal storage best = buying[highest];
        address buyer = best.user;
        uint buyer_price = best.price;
        uint buyer_amount = best.amount;
        require(best.price >= price);
        if (best.amount <= amount) {
            sold = best.amount;
            delete buying[highest];
            users[buyer].exists = false;
        } else {
            sold = amount;
            best.amount -= sold;
        }
        buyer.transfer(buyer_price * buyer_amount - price * sold);
        msg.sender.transfer(msg.value + price * sold);
        return (sold, buyer);
    }
    
    function getQueue(bool b) view public returns (Proposal[] ret) {
        if (b == true) {
            ret = buying;
        } else {
            ret = selling;
        }
        return ret;
    }

}
