// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DutchAuction {
    //Владелец смарт контракта
    address public owner;
    // продолжительность аукциона
    uint constant DURATION = 2 days;
    // на сколько будет снижаться цена
    uint constant FEE = 10;

    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    // массив с аукционами
    Auction[] public auctions;

    constructor() {
        owner = msg.sender;
    }

    event AuctionCreated(
        uint index,
        string itemName,
        uint startingPrice,
        uint duration
    );
    event AuctionEnded(
        uint index,
        uint finalPrice,
        address buyer
    );

    // создаем аукцион и оповещаем об этом
    function createAuction(
        uint _startingPrice,
        uint _discountRate,
        string calldata _item,
        uint _duration
    ) external {
        uint duration = _duration == 0 ? DURATION : _duration;

        require(
            _startingPrice >= duration * _discountRate,
            "incorrect starting price"
        );

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            finalPrice: _startingPrice,
            startAt: block.timestamp,
            endsAt: block.timestamp + duration,
            discountRate: _discountRate,
            item: _item,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreated(
            auctions.length - 1,
            _item,
            _startingPrice,
            duration
        );
    }

    // узнаем текущую цену лота
    function getPrice(uint index) public view returns (uint) {
        Auction memory currentAuction = auctions[index];
        require(!currentAuction.stopped, "auction has stopped");
        // сколько времени прошло с начала аукциона
        uint elapsed = block.timestamp - currentAuction.startAt;
        // какова скидка на текущий момент
        uint discount = currentAuction.discountRate * elapsed;
        // возвращаем текущую цену лота
        return currentAuction.startingPrice - discount;
    }

    // покупаем лот
    function buy(uint index) external payable {
        Auction storage  currentAuction = auctions[index];
        require(!currentAuction.stopped, "auction has stopped");
        require(block.timestamp < currentAuction.endsAt, "ended");
        uint currentPrice = getPrice(index);
        require(msg.value >= currentPrice, "not enough money");
        currentAuction.stopped = true;
        currentAuction.finalPrice = currentPrice;
        // разница между суммой лота и той суммой, которую отправил покупатель
        uint refund = msg.value - currentPrice;
        // если разница больше 0, то отправляем ее покупателю
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        // отправляем сумму лота продавцу лота с вычетом 10% за комиссию площадки
        currentAuction.seller.transfer(
            currentPrice - ((currentPrice * FEE) / 100)
        );
        emit AuctionEnded(index, currentPrice, msg.sender);
    }
}
