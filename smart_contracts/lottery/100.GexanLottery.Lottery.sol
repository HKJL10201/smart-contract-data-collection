pragma solidity ^0.4.20;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


contract Lottery is Ownable {


    address public drawer;

    struct Game {
        uint startTime;
        uint jackpot;
        uint reserve;
        uint price;
        bytes winNumbers;
        mapping(byte => bool) winNumbersMap;
        Ticket[] tickets;
        uint checkWinTicketLevel;
        uint[][] winTicketIndices;
        uint[] winLevelAmounts;
        uint needPlayersTransfer;
        uint addToJackpotAmount;
        uint addToReserveAmount;
        uint bitcoinBlockIndex;
        string bitcoinBlockHash;

    }

    struct Ticket {
        address user;
        bytes numbers;
    }

    mapping(address => uint[2][]) playerTickets;



    Game[] public games;

    uint public gameIndex;

    uint public gameIndexToBuy;

    uint public checkGameIndex;

    uint public numbersCount;

    uint public numbersCountMax;

    uint public ticketCountMax;

    uint public jackpotGuaranteed;

    uint public disableBuyingTime;

    uint[] public winPercent;
    
    uint[] public pricePlus;

    address public dividendsWallet;

    address public technicalWallet;

    uint public dividendsPercent;

    uint public technicalPercent;

    uint public nextPrice;
    
    uint public fixedWin;

    uint public intervalTime;

    uint public percentDivider = 10000;
    

    modifier onlyDrawer() {
        require(msg.sender == drawer);
        _;
    }
    function setDrawer(address _drawer) public onlyOwner {
        drawer = _drawer;
    }


    event LogDraw(uint indexed gameIndex, uint startTime, uint bitcoinBlockIndex, bytes numbers, uint riseAmount, uint transferAmount, uint addToJackpotAmount, uint addToReserveAmount);

    event LogReserveUsed(uint indexed gameIndex, uint amount);


    function Lottery() public {
        numbersCount = 5;

        dividendsPercent = 1000;
        technicalPercent = 500;


        drawer = msg.sender;
        dividendsWallet = msg.sender;
        technicalWallet = msg.sender;



        disableBuyingTime = 1 hours;
        intervalTime = 6 hours;

        nextPrice = 100000000;
        fixedWin = 200000000;
        games.length = 2;

        
        numbersCountMax = 36;
        winPercent = [0, 0, 10, 10, 20, 60];
        pricePlus = [100000000,600000000,1900000000,4800000000,9700000000,19400000000,34300000000];
        jackpotGuaranteed = 100000000000;
        ticketCountMax = 1000000;
        games[0].startTime = 1556402450;
        

        games[0].price = nextPrice;
        games[1].price = nextPrice;

        games[1].startTime = games[0].startTime + intervalTime;
    }

    function startTime() public view returns (uint){
        return games[gameIndex].startTime;
    }

    function closeTime() public view returns (uint){
        return games[gameIndex].startTime - disableBuyingTime;
    }

    function addReserve() public payable {
        require(checkGameIndex == gameIndex);
        games[gameIndex].reserve += msg.value;
    }

    function isNeedCloseCurrentGame() public view returns (bool){
        return games[gameIndex].startTime < disableBuyingTime + now && gameIndexToBuy == gameIndex;
    }

    function closeCurrentGame(uint bitcoinBlockIndex) public onlyDrawer {
        require(isNeedCloseCurrentGame());

        games[gameIndex].bitcoinBlockIndex = bitcoinBlockIndex;
        gameIndexToBuy = gameIndex + 1;
    }

    function() public payable {
            uint[] memory numbers;
            numbers = new uint [](msg.data.length);
            for (uint i = 0; i < numbers.length; i++) {
                numbers[i] = uint((msg.data[i] >> 4) & 0xF) * 10 + uint(msg.data[i] & 0xF);
            }
            buyTicket(numbers);
    }
    
    

    function buyTicket(uint[] numbers) public payable {
        
        uint totPrice = 0;
        uint nextNumbers = 0;
        uint nowNumber = 0;
        uint dels = 0;
        uint totTickets = 0;
        uint i = 0;
        
        
        for (i = 0; i < numbers.length; i++) {
            if(nextNumbers == 0) {
                nextNumbers = numbers[i];
                require(nextNumbers>4 && nextNumbers<12);
                nowNumber=0;
            }
            
            if(nowNumber == nextNumbers) {
                dels = nextNumbers - 5;
                totPrice += pricePlus[dels];
                nextNumbers=0;
                totTickets++;
            }
            else {
                nowNumber++;
            }
            
        }

        require(msg.value == totPrice);
        
        Game storage game = games[gameIndexToBuy];
        
        require(game.tickets.length + totTickets <= ticketCountMax);

        i = 0;
        nextNumbers = 0;
        while (i < numbers.length) {
            nextNumbers = numbers[i++];
            bytes memory bet = new bytes(nextNumbers);

            for (uint j = 0; j < nextNumbers; j++) {
                bet[j] = byte(numbers[i++]);
            }

            require(noDuplicates(bet));

            playerTickets[msg.sender].push([gameIndexToBuy, game.tickets.length]);

            game.tickets.push(Ticket(msg.sender, bet));

        }

    }

    function getPlayerTickets(address player, uint offset, uint count) public view returns (int [] tickets){
        uint[2][] storage list = playerTickets[player];
        if (offset >= list.length) return tickets;

        uint k;
        uint n = offset + count;
        if (n > list.length) n = list.length;

        tickets = new int []((n - offset) * (11 + 5));

        for (uint i = offset; i < n; i++) {
            uint[2] storage info = list[list.length - i - 1];
            uint _gameIndex = info[0];

            tickets[k++] = int(_gameIndex);
            tickets[k++] = int(info[1]);
            tickets[k++] = int(games[_gameIndex].startTime);

            if (games[_gameIndex].winNumbers.length == 0) {
                tickets[k++] = - 1;
                tickets[k++] = int(pricePlus[games[_gameIndex].tickets[info[1]].numbers.length-5]);

                for (uint j = 0; j < 11; j++) {
                    if(j < games[_gameIndex].tickets[info[1]].numbers.length) {
                        tickets[k++] = int(games[_gameIndex].tickets[info[1]].numbers[j]);
                    }
                    else {
                        tickets[k++] = 0;
                    }
                }
            }
            else {
                uint winNumbersCount = getEqualCount(games[_gameIndex].tickets[info[1]].numbers, games[_gameIndex]);
                tickets[k++] = int(games[_gameIndex].winLevelAmounts[winNumbersCount]);
                tickets[k++] = int(pricePlus[games[_gameIndex].tickets[info[1]].numbers.length-5]);

                for (j = 0; j < 11; j++) {
                    if(j < games[_gameIndex].tickets[info[1]].numbers.length) {
                        if (games[_gameIndex].winNumbersMap[games[_gameIndex].tickets[info[1]].numbers[j]]) {
                            tickets[k++] = - int(games[_gameIndex].tickets[info[1]].numbers[j]);
                        }
                        else {
                            tickets[k++] = int(games[_gameIndex].tickets[info[1]].numbers[j]);
                        }
                    }
                    else {
                         tickets[k++] = 0;
                    }
                }
            }
        }
    }

    function getAllTickets() public view returns (int [] tickets){
        uint n = gameIndexToBuy + 1;

        uint ticketCount;
        for (uint _gameIndex = 0; _gameIndex < n; _gameIndex++) {
            ticketCount += games[_gameIndex].tickets.length;
        }

        tickets = new int[](ticketCount * (11 + 5));
        uint k;

        for (_gameIndex = 0; _gameIndex < n; _gameIndex++) {
            Ticket[] storage gameTickets = games[_gameIndex].tickets;
            for (uint ticketIndex = 0; ticketIndex < gameTickets.length; ticketIndex++) {

                tickets[k++] = int(_gameIndex);
                tickets[k++] = int(ticketIndex);
                tickets[k++] = int(games[_gameIndex].startTime);

                if (games[_gameIndex].winNumbers.length == 0) {
                    tickets[k++] = - 1;
                    tickets[k++] = int(pricePlus[games[_gameIndex].tickets[ticketIndex].numbers.length-5]);


                    for (uint j = 0; j < 11; j++) {
                        if(j < games[_gameIndex].tickets[ticketIndex].numbers.length) {
                            tickets[k++] = int(games[_gameIndex].tickets[ticketIndex].numbers[j]);
                        }
                        else {
                            tickets[k++] = 0;
                        }
                    }
                }
                else {
                    uint winNumbersCount = getEqualCount(games[_gameIndex].tickets[ticketIndex].numbers, games[_gameIndex]);
                    tickets[k++] = int(games[_gameIndex].winLevelAmounts[winNumbersCount]);
                    tickets[k++] = int(pricePlus[games[_gameIndex].tickets[ticketIndex].numbers.length-5]);


                    for (j = 0; j < 11; j++) {
                        if(j < games[_gameIndex].tickets[ticketIndex].numbers.length) {
                            if (games[_gameIndex].winNumbersMap[games[_gameIndex].tickets[ticketIndex].numbers[j]]) {
                                tickets[k++] = - int(games[_gameIndex].tickets[ticketIndex].numbers[j]);
                            }
                            else {
                                tickets[k++] = int(games[_gameIndex].tickets[ticketIndex].numbers[j]);
                            }
                        }
                        else {
                            tickets[k++] = 0;
                        }
                    }
                }
            }
        }
    }

    function getGames(uint offset, uint count) public view returns (uint [] res){
        if (offset > gameIndex) return res;

        uint k;
        uint n = offset + count;
        if (n > gameIndex + 1) n = gameIndex + 1;
        res = new uint []((n - offset) * (numbersCount + 10));

        for (uint i = offset; i < n; i++) {
            uint gi = gameIndex - i;
            Game storage game = games[gi];
            res[k++] = gi;
            res[k++] = game.startTime;
            res[k++] = game.jackpot;
            res[k++] = game.reserve;
            res[k++] = game.price;
            res[k++] = game.tickets.length;
            res[k++] = game.needPlayersTransfer;
            res[k++] = game.addToJackpotAmount;
            res[k++] = game.addToReserveAmount;
            res[k++] = game.bitcoinBlockIndex;

            if (game.winNumbers.length == 0) {
                for (uint j = 0; j < numbersCount; j++) {
                    res[k++] = 0;
                }
            }
            else {
                for (j = 0; j < numbersCount; j++) {
                    res[k++] = uint(game.winNumbers[j]);
                }
            }
        }
    }

    function getWins(uint _gameIndex, uint offset, uint count) public view returns (uint[] wins){
        Game storage game = games[_gameIndex];
        uint k;
        uint n = offset + count;
        uint[] memory res = new uint [](count * 4);

        uint currentIndex;

        for (uint level = numbersCount; level > 1; level--) {
            for (uint indexInlevel = 0; indexInlevel < game.winTicketIndices[level].length; indexInlevel++) {
                if (offset <= currentIndex && currentIndex < n) {
                    uint ticketIndex = game.winTicketIndices[level][indexInlevel];
                    Ticket storage ticket = game.tickets[ticketIndex];
                    res[k++] = uint(ticket.user);
                    res[k++] = level;
                    res[k++] = ticketIndex;
                    res[k++] = game.winLevelAmounts[level];

                } else if (currentIndex >= n) {
                    wins = new uint[](k);
                    for (uint i = 0; i < k; i++) {
                        wins[i] = res[i];
                    }
                    return wins;
                }
                currentIndex++;
            }
        }
        wins = new uint[](k);
        for (i = 0; i < k; i++) {
            wins[i] = res[i];
        }
    }

    function noDuplicates(bytes array) public pure returns (bool){
        for (uint i = 0; i < array.length - 1; i++) {
            for (uint j = i + 1; j < array.length; j++) {
                if (array[i] == array[j]) return false;
            }
        }
        return true;
    }

    function getWinNumbers(string bitcoinBlockHash, uint _numbersCount, uint _numbersCountMax) public pure returns (bytes){
        bytes32 random = keccak256(bitcoinBlockHash);
        bytes memory allNumbers = new bytes(_numbersCountMax);
        bytes memory winNumbers = new bytes(_numbersCount);

        for (uint i = 0; i < _numbersCountMax; i++) {
            allNumbers[i] = byte(i + 1);
        }

        for (i = 0; i < _numbersCount; i++) {
            uint n = _numbersCountMax - i;

            uint r = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % n;

            winNumbers[i] = allNumbers[r];

            allNumbers[r] = allNumbers[n - 1];

        }
        return winNumbers;
    }

    function isNeedDrawGame(uint bitcoinBlockIndex) public view returns (bool){
        Game storage game = games[gameIndex];
        return bitcoinBlockIndex > game.bitcoinBlockIndex && game.bitcoinBlockIndex > 0 && now >= game.startTime;
    }

    function drawGame(uint bitcoinBlockIndex, string bitcoinBlockHash) public onlyDrawer {
        Game storage game = games[gameIndex];
        uint winNumbersCount;
        require(isNeedDrawGame(bitcoinBlockIndex));

        game.bitcoinBlockIndex = bitcoinBlockIndex;
        game.bitcoinBlockHash = bitcoinBlockHash;
        game.winNumbers = getWinNumbers(bitcoinBlockHash, numbersCount, numbersCountMax);

        for (uint i = 0; i < game.winNumbers.length; i++) {
            game.winNumbersMap[game.winNumbers[i]] = true;
        }

        game.winTicketIndices.length = numbersCount + 1;
        game.winLevelAmounts.length = numbersCount + 1;

        for (uint ticketIndex = 0; ticketIndex < game.tickets.length; ticketIndex++) {

            winNumbersCount = 0;
            for (uint j = 0; j < game.tickets[ticketIndex].numbers.length; j++) {
                if (game.winNumbersMap[game.tickets[ticketIndex].numbers[j]]) {
                    winNumbersCount++;
                }
            }
            
            if(winPercent[winNumbersCount] > 0) {
                game.winTicketIndices[winNumbersCount].push(ticketIndex);
            }
        }
        
        uint riseAmount = game.tickets.length * game.price;

        uint technicalAmount = riseAmount * technicalPercent / percentDivider;
        uint dividendsAmount = riseAmount * dividendsPercent / percentDivider;

        technicalWallet.transfer(technicalAmount);
        dividendsWallet.transfer(dividendsAmount);
        
        
        games.length++;

        games[gameIndex + 1].startTime = games[gameIndex].startTime + intervalTime;
        games[gameIndex + 1].price = nextPrice;

    }

    function calcWins(Game storage game) private {
        game.checkWinTicketLevel = numbersCount;
        uint i = 0;
        uint riseAmount = game.tickets.length * game.price * (percentDivider - technicalPercent - dividendsPercent) / percentDivider;
        uint freeAmount = 0;
        uint fromReserve = 0;

        for (i = 3; i < numbersCount; i++) {
            
            
            
            uint winCount = game.winTicketIndices[i].length;
            uint winAmount = riseAmount * winPercent[i] / 100;
            if (winCount > 0) {
                game.winLevelAmounts[i] = winAmount / winCount;
                game.needPlayersTransfer += winAmount;
                
                for(uint j = 0; j < winCount; j++) {
                    //transfer amount
                }
               
                
            }
            else {
                freeAmount += winAmount;
            }
        }
        freeAmount += riseAmount * winPercent[numbersCount] / 100;


        uint winFixedCount = game.winTicketIndices[2].length;
        uint reserve = game.reserve;
        
        if (winFixedCount > 0) {
            
            uint needPayFixed = fixedWin * winFixedCount;
            
            if(freeAmount<needPayFixed) {
                fromReserve = needPayFixed - freeAmount;
                if (fromReserve > reserve) fromReserve = reserve;
                reserve -= fromReserve;
                freeAmount += fromReserve;
                needPayFixed = freeAmount;
                LogReserveUsed(checkGameIndex, fromReserve);
            }
            game.winLevelAmounts[2] = needPayFixed / winFixedCount;
            game.needPlayersTransfer += needPayFixed;

            for(i = 0; i < winCount; i++) {
                //transfer amount
            }
            freeAmount -= needPayFixed;
            
        }

        uint winJackpotCount = game.winTicketIndices[numbersCount].length;

        uint jackpot = game.jackpot;
        

        if (winJackpotCount > 0) {
            if (jackpot < jackpotGuaranteed) {
                fromReserve = jackpotGuaranteed - jackpot;
                if (fromReserve > reserve) fromReserve = reserve;

                reserve -= fromReserve;
                jackpot += fromReserve;

                LogReserveUsed(checkGameIndex, fromReserve);
            }

            game.winLevelAmounts[numbersCount] = jackpot / winJackpotCount;

            game.needPlayersTransfer += jackpot;
            jackpot = 0;
            
            for(i = 0; i < winJackpotCount; i++) {
                //transfer jackpot
            }
        }

        if (reserve < jackpotGuaranteed) {
            game.addToReserveAmount = freeAmount;
        } else {
            game.addToJackpotAmount = freeAmount;
        }
        games[checkGameIndex].jackpot += jackpot + game.addToJackpotAmount;
        games[checkGameIndex].reserve += reserve + game.addToReserveAmount;

    }

    function getEqualCount(bytes numbers, Game storage game) constant private returns (uint count){
        for (uint i = 0; i < numbers.length; i++) {
            if (game.winNumbersMap[numbers[i]]) count++;
        }
    }

    function setJackpotGuaranteed(uint _jackpotGuaranteed) public onlyOwner {
        jackpotGuaranteed = _jackpotGuaranteed;
    }

}
