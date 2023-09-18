// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// CriptoCurrency "SkillCoin"
contract TestCoin {

    address owner; // адрес пользователя(владельца)
    mapping(address => uint) public balances; // балансы всех пользователей mapping - словарь

    // При создании контракта(запуске) будет вызван конструктор
    constructor() public {
        owner = msg.sender; // запомнили пользователя создавшего контракт - он и владелец
    }
    
    // Coin creation and sending to user
    // Каждой переменной необходимо задать тип
    // public - делает функцию общедоступной
    function create_coin(address reciever, uint amount) public {
        // Проверка создателя монеты
        require(msg.sender == owner, "Only owner can create coins!");
        balances[reciever] += amount; // отправка денег(прибавление к балансу)
    }
    
    function send_coin(address reciever, uint amount) public {
        // Проверка что у отправителя достаточно денег
        require(balances[msg.sender] >= amount + 1, "Insufficient balance!");
        require(msg.sender != reciever, "Cannot send coin to yourself.");
        
        balances[msg.sender] -= amount + 1; // Вычитаем сумму перевода и коммисию
        balances[reciever] += amount;
        balances[owner] += 1; // комиссия идет владельцу
    }
}
