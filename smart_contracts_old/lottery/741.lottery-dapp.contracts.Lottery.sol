pragma solidity ^0.5.1;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {

    address public owner = msg.sender;
    // adress zero = 0x0000000000000000000000000000000000000000;
    modifier onlyOwner {
        require(msg.sender == owner, "only owner can execute this");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


contract Lottery is Ownable{

    using SafeMath for uint;

    uint price = 1000000000000000000; //TODO change it  // 1 ether =  10000000000000000000 wei
    uint fee = 20000000000000000 ; // 2% fee

    uint[qntNumbers] winnerGame ;

    //winnerGame = [1,2,3,4,5,6,7,8];

    //[7,15,18,19,29,30,46,50]  for 60 nummbers
     //[6,7,9,10,11,15,18,19] for 20
     //[2,10,18,19,20,22,27,29] for 32

    uint constant qntNumbers  = 8;
    uint constant numberMax = 32; //TODO make the caculations and change it

    uint timerDelay = 45; //60*60*23; //23h
    uint lastGameTime= now;

    //a game is 8 numbers of the array: if array.lenght == 16, nbGames == 2
    mapping(address=>uint[]) addressToGame;
    address payable[] players;
    address payable[]  winners;

    uint Prize;
    uint ownerReward;

    uint[] winnersGameList;



    function isNewPlayer(address _address) private view returns(bool){
        //address NewPlayer = msg.sender;

        for (uint i=0;i<players.length;i++){
            if ( players[i]==_address){

                return false;
            }
        }
        return true;


    }

    event printInt(uint integer);
    event printBool(bool boolean);

    event gamePosted(uint[qntNumbers] _numbers);


    //TODO make a test for multiple games
    function postGame(uint[qntNumbers] memory _numbers) public payable costs(price) returns (uint[] memory){

        Prize +=price-fee;
        ownerReward = address(this).balance - Prize;

        assert(address(this).balance >= Prize);

        address payable NewPlayer = msg.sender;
        bool _isNewPlayer = isNewPlayer(NewPlayer);



        emit printBool(_isNewPlayer);

        if (_isNewPlayer){

            players.push(NewPlayer);
            addressToGame[NewPlayer] = _numbers;

        }else{

            uint[] storage olderGames = addressToGame[NewPlayer];

                //uint totalNumbers = olderGames.length;

                //emit printInt(totalNumbers);

                for (uint i=0;i<qntNumbers;i++){

                    olderGames.push(_numbers[i]);

                    }


             }

        emit gamePosted(_numbers);

        //return _isNewPlayer;

        if ( getTimeNextGame()==0){

            lastGameTime = now;

            playRound();

        }


        return addressToGame[NewPlayer];

    }




    function getEntropy() private view returns(uint){

        //Uncomment this secction to get real entropy



        uint added = 0;

        for(uint i=0;i<winnersGameList.length;i++){

            added += winnersGameList[i];
        }


        uint entropy = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty,added)));

        return entropy;



        //[2,10,18,19,20,22,27,29] for 32 winning game for entropy 1;
        //return 1;

    }



    function getWinnerGame() public returns(uint[qntNumbers] memory){




        bytes4[8] memory x = [bytes4(0) , 0 ,0,0,0,0,0,0 ];

        uint entropy = getEntropy();
        /*uint blockNumber = block.number;
        bytes32 blockHash1 = blockhash(blockNumber-1);
        bytes32 blockHash6 = blockhash(blockNumber-6);
        bytes32 blockHash13 = blockhash(blockNumber-13);*/

        bytes32 hash = keccak256(abi.encodePacked(entropy));//,ListWinners,games,blockHash1,blockHash6,blockHash13));
        //return hash;

        assembly {
            mstore(x, hash)
            mstore(add(x, 28), hash)
            mstore(add(x, 56), hash)
            mstore(add(x, 84), hash)
            mstore(add(x, 112), hash)
            mstore(add(x, 140), hash)
            mstore(add(x, 168), hash)
            mstore(add(x, 196), hash)
        }

        uint n0 = uint32 (x[0]);
        n0 = n0%numberMax;
        uint n1 = uint32 (x[1]);
        n1 = n1%numberMax;
        uint n2 = uint32 (x[2]);
        n2 = n2%numberMax;
        uint n3 = uint32 (x[3]);
        n3 = n3%numberMax;
        uint n4 = uint32 (x[4]);
        n4 = n4%numberMax;
        uint n5 = uint32 (x[5]);
        n5 = n5%numberMax;
        uint n6 = uint32 (x[6]);
        n6 = n6%numberMax;
        uint n7 = uint32 (x[7]);
        n7 = n7%numberMax;

        uint[qntNumbers] memory tabNumbers = [n0,n1,n2,n3,n4,n5,n6,n7];

        quickSort(tabNumbers,0,tabNumbers.length -1);

        removeDoubles(tabNumbers);

        winnerGame = tabNumbers;

        //payer();

        lastGameTime = now;

        return winnerGame;



    }

    function removeDoubles(uint[qntNumbers] memory tab) private{

        bool a=true;
        bool b=true;
        bool c=true;
        bool d=true;


            for (uint i=0;i<tab.length;i++){

                if(tab[0]==0){
                    tab[0]=numberMax;
                }

                if (tab[i]> numberMax){
                    tab[i] = tab[i]%numberMax;
                    b=false;
                }

                if ( (i+1 < tab.length)&& (tab[i]==tab[i+1])){

                    tab[i+1]= tab[i+1] + 1;
                    c=false;
               }
            }

            if(a&&b&&c&&d){
                quickSort(tab,0,tab.length -1);
                //emit tabCheck(tab);
                return;
            }

            quickSort(tab,0,tab.length -1);

            removeDoubles(tab);

    }

    function quickSort(uint[qntNumbers] memory tab, uint left, uint right) private {
        uint i = left;
        uint j = right;
        uint mid = tab[left + (right - left) / 2];
        while (i <= j) {
            while (tab[i] < mid) i++;
            while (mid < tab[j]) j--;
            if (i <= j) {
                (tab[i], tab[j]) = (tab[j], tab[i]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(tab, left, j);
        if (i < right)
            quickSort(tab, i, right);

    }

    /*function setWinnerGameeMannually(uint[qntNumbers] memory _winnerGame) public onlyOwner{

        winnerGame = _winnerGame;
    }*/

    function checkIfGameIsWin(uint[qntNumbers] memory _winnerGame ,uint[] memory _gameArray, uint _start,uint _end) private pure returns(bool){




        require( _end -_start==qntNumbers-1,"not good quantity of numbers");
        require( (_end+1)%8 == 0 , "not good indexes _start and _end");

        //require( _gameArray)


        for(uint i=_start;i<=_end;i++){

            if (_winnerGame[i-_start]!=_gameArray[i]){

                return false;

            }


        }
        return true;

    }

    function searchWinGameInArray(uint[qntNumbers] memory __winnerGame, uint[] memory __gameArray ) private pure returns(bool){

        uint nbGamesTotal = __gameArray.length/qntNumbers;

        for (uint n = 0;n<nbGamesTotal;n++){

            uint start = qntNumbers*n;
            uint end = qntNumbers*n+qntNumbers-1;

            if (checkIfGameIsWin(__winnerGame,__gameArray,start,end)){

                return true;


            }


        }
        return false;

    }


    //TODO run the test to see if the winners are deleted from players list
    function findWinners() private {// returns (address payable[] memory){

        winnerGame = getWinnerGame();

        for(uint i=0;i<winnerGame.length;i++){

            winnersGameList.push(winnerGame[i]);

        }



        for(uint i=0; i<players.length;i++){

            address payable currentPlayer = players[i];
            uint[] storage gameListCurrentPlayer = addressToGame[currentPlayer];

            if(searchWinGameInArray(winnerGame,gameListCurrentPlayer)){

                //pushes the winner to the wining list
                winners.push(currentPlayer);

            }

            //delete the player from the list of player, even if he doesnt win
            delete addressToGame[currentPlayer];


        }

        //we could remove the return, but its easier to debug like this
        //return winners;

    }


    function payerWinners() private returns (uint) {

        uint totalWinners = winners.length;

        if (totalWinners == 0){

            return 0;

        }else{

            uint individualPrize = Prize/totalWinners;
            Prize = 0;

            for(uint i=0;i<totalWinners;i++){

                winners[i].transfer(individualPrize);
                delete winners[i];


            }

            return individualPrize;


        }



    }

    function playRound() private {

        findWinners();
        payerWinners();


    }

   modifier costs(uint amount){
        require(msg.value >= amount, "insuficient amount");
        _;
    }


    function getTimeNextGame() public view returns (uint){

        uint time = timerDelay + lastGameTime - now ;
        if (time>timerDelay){
            time=0;
        }

        return time;
    }

    function getLastGameTime() public view returns(uint){

        return lastGameTime;

    }
    function getNextGameTimestamp() public view returns(uint){

        return lastGameTime+timerDelay;

    }

    function getComulatedPrize() public view returns (uint){
        //return address(this).balance;
        return Prize;
    }

    function getOwnerReward() public view returns (uint){
        //return address(this).balance;
        return ownerReward;
    }

    function withdrawAsOwner() public onlyOwner{

        uint toTransfer = ownerReward;
        ownerReward = 0;

        msg.sender.transfer(toTransfer);


    }

    function getOwner() public view returns (address){

      return owner;
    }

    function showWinnersGame() public view returns(uint[] memory){

        return winnersGameList;

    }
    function showPlayersGames(address _address) public view returns(uint[] memory){
      return addressToGame[_address];

    }


}
