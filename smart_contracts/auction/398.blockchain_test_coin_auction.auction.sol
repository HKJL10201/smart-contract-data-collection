// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Market {
    
    address payable public seller; // на этот адрес отправляются деньги со смарта
    
    address highest_bidder; // участник с максимальной ставкой
    
    uint public highest_bid; // max bid 
    
    uint end_time; // время окончания продаж
    
    mapping (address => uint) cash_back; // для возврата проигравших ставок
    
    constructor(
        address payable _seller,
        uint auction_interval // time in seconds, auction time
    ) public {
        seller = _seller;
        end_time = block.timestamp + auction_interval;
    }
    
    // Ставка
    function make_bid() public payable {
        require(block.timestamp < end_time, "Auction ended");
        require(msg.value > highest_bid, "Invalid bid");
        if(highest_bid != 0) {
            // предыдущий highest_bidder получает обратно свою ставку
            cash_back[highest_bidder] += highest_bid;
        }
        
        highest_bid = msg.value;
        highest_bidder = msg.sender;
    }

    function with_draw(address payable sender) public returns (bool) {
        require(sender == msg.sender, "Invalid address");
        uint amount = cash_back[sender]; // сумма возврата
        if (amount > 0) {
            //Посылаем сумму деньги обратно
            if (sender.send(amount)) {
                // Обнуляем "долг"
                cash_back[sender] = 0;
                return true;
            }
            
        }
        
        return false;
    }
    
    function finalize_auction() public {
        require(block.timestamp >= end_time, "Auction hasn`t ended yet!");
        require(seller == msg.sender, "Only seller can close auction!");
        
        seller.transfer(highest_bid);
    }
}
