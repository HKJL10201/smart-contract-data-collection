// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DutchAuction {
    //Владелец смарт контракта
    address public owner;
    // продолжительность аукциона
    uint constant DURATION = 2 days;
    // на сколько будет снижаться цена
    uint constant FEE = 10;
    address payable seller;
    uint startingPrice;
    uint finalPrice;
    uint startAt;
    uint endsAt;
    uint discountRate;
    string item;
    bool stopped;

    constructor(
        uint _startingPrice,
        uint _discountRate,
        string memory _item
        ) {
        owner = msg.sender;

        require(
            _startingPrice >= DURATION * _discountRate,
            "incorrect starting price"
        );

            seller = payable(msg.sender);
            startingPrice = _startingPrice;
            finalPrice = _startingPrice;
            startAt = block.timestamp;
            endsAt = block.timestamp + DURATION;
            discountRate = _discountRate;
            item = _item;
            stopped = false;

        emit AuctionCreated(
            _item,
            _startingPrice,
            DURATION
        );
    }

    event AuctionCreated(
        string itemName,
        uint startingPrice,
        uint duration
    );
    event AuctionEnded(
        uint finalPrice,
        address buyer
    );

    modifier notStopped {
        require(!stopped, 'auction is stopped');
        require(block.timestamp < endsAt, "ended");
        _;
    }

    // узнаем текущую цену лота
    function getPrice() public view notStopped returns (uint) {
        // сколько времени прошло с начала аукциона
        uint elapsed = block.timestamp - startAt;
        // какова скидка на текущий момент
        uint discount = discountRate * elapsed;
        // возвращаем текущую цену лота
        return startingPrice - discount;
    }

    // покупаем лот
    function buy() external payable notStopped{
        uint currentPrice = getPrice();
        require(msg.value >= currentPrice, "not enough money");
        stopped = true;
        finalPrice = currentPrice;
        // разница между суммой лота и той суммой, которую отправил покупатель
        uint refund = msg.value - currentPrice;
        // если разница больше 0, то отправляем ее покупателю
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        // отправляем сумму лота продавцу лота с вычетом 10% за комиссию площадки
        seller.transfer(
            currentPrice - ((currentPrice * FEE) / 100)
        );
        emit AuctionEnded(currentPrice, msg.sender);
    }
}
