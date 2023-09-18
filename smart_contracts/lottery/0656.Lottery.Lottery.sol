pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function withdraw(uint amount) onlyOwner public{
        msg.sender.transfer(amount);
    }
}

contract random{
    uint nonce = 1;
    function rand(uint min, uint max) internal returns (uint){
        nonce++;
        return uint((nonce + block.number))%(min+max)-min;
    }
}

/**
 * Лоттерейка - контракт в стиле модных мини лоттерей, которые можно было купитьь в любом журнальном киоске
 * года до 2012. Сколько радости и грусти, вызывали эти маленькие бумажки, по 10 рублей.
 * Солько было сломано ногтей о слой для стирания, или об уголок трубочки-билетика, которую вы,
 * с жадными глазами, полными надежды и азарта, разворачивали, и оттягивали до последнего момент прочтения надписи.
 * 
 * В этом стиле сделала и наша Лоттерейка. Всё очень просто - платишь за игру, и моментально узнаешь размер своего приза.
 * 
 * Удачи!
 */
contract Lottery is owned, random{
    event Win(address recipient, uint amount, uint variant);
    event Lose(address recipient, uint variant);
    event Return(address recipient, uint amount);
    event Deposit(uint amount);
    
    string public description = "Instant lottery. Just send 0.02 ETH to Play method and enjoy your prize!";
    uint public playCost = 2000000000000000; //wei in 0.02 eth
    uint public maxWinRatio = 5;
    uint public secondPrizeRatio = 2;
    uint public thirdPrizeDelimiter = 2;
    uint public fourthPrizeDelimiter = 3;
    uint public games = 0;
    
    function play() public payable{
        assert(msg.value >= playCost); //Хотя бы стоимость одной игры есть у надписи
        assert(playCost*maxWinRatio <= this.balance); //Проверяем, можем-ли мы позволить себе максимальный приз
        
        if(msg.value > playCost){
            msg.sender.transfer(msg.value - playCost); //если переведено было больше стоимости игры, возвращаем (это полвзоляет пофиксить проблему Mist)
            Return (msg.sender, msg.value - playCost);
        }
        
	games++;
	
        //Важные проверки выполнены, теперь можно играть :)
        uint lot =  rand(1, 20); //Получаем число для игры
        
        
        //Получаем максимальный приз
        if(lot == 6){ 
            msg.sender.transfer(playCost * maxWinRatio);
            Win(msg.sender,playCost * maxWinRatio, lot);
            return;
        }
        
        //Получаем стоимость еще одной игры
        if(lot == 10 || lot == 20){ 
            msg.sender.transfer(playCost);
            Win(msg.sender,playCost, lot);
            return;
        }
        
        //Получаем половину стоимости игры
        if(lot == 11 || lot == 16){ 
            nonce++;
            msg.sender.transfer(playCost/thirdPrizeDelimiter);
            Win(msg.sender, playCost/thirdPrizeDelimiter, lot);
            return;
        }
        
        //Получаем 1/3 стоимости игры
        if(lot == 14 || lot == 17 || lot == 5 || lot == 12){ 
            nonce++;
            msg.sender.transfer(playCost/fourthPrizeDelimiter);
            Win(msg.sender, playCost/fourthPrizeDelimiter, lot);
            return;
        }
        
        //Получаем 1/4 стоимости игры
        if(lot == 2 || lot == 7 ){ 
            nonce++;
            msg.sender.transfer(playCost/(thirdPrizeDelimiter*2));
            Win(msg.sender, playCost/(thirdPrizeDelimiter*2), lot);
            return;
        }
        
        //Получаем три стоимости игры
        if(lot == 13){ 
            msg.sender.transfer(playCost*secondPrizeRatio);
            Win(msg.sender, playCost*secondPrizeRatio, lot);
            return;
        }
        
        
        //Суперприз
        if(lot == 15 && this.balance%2620 == 0 ){ 
	    uint prize = this.balance / rand(3,30);
            msg.sender.transfer(prize);
            Win(msg.sender, prize, lot);
            return;
        }
        
        Lose(msg.sender, lot);
        return;
    }
    
    /*
    Пополнение призового фонда
    */
    function () payable{
	    play();
    }
    
    function deposit() payable{
        Deposit(msg.value);
    }
    
}
