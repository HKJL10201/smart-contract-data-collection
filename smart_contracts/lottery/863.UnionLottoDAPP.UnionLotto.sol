pragma solidity ^0.4.22;
pragma experimental ABIEncoderV2;
contract SenoirAuthority {
    address authority;
    mapping(string=>address) UnionLottos;
    string [] dates;
    
    constructor() public {
        authority = 0x4C02D8D6CF951E636642a21F43BBB46C7fBF9342;
    }
    function createUnionLotto(string date) public {
       dates.push(date);
       UnionLottos[date] = new UnionLotto(date);
    }
    
    function getLottos() constant public returns (string []) {
        return dates;
    }
    
    function getLatest() constant returns (string){
        return dates[dates.length-1];
    }
    
    function getContractAddress(string date) constant returns (address){
        return UnionLottos[date];
    }
    
    
    function isAuthority() constant returns (bool) {
        return authority == msg.sender;
    }
}

contract UnionLotto {
    string public id;
    string public date;
    uint public firstPrize;
    uint public secondPrize;
    uint[7] public winnerNumbers;
    // uint temp;
    uint private prizePond;
    //     
    address private authority;
    // address private taxAuthorities;
    // address private charity;
    mapping(address=>Bet[]) private bets;
    address [] public users;
    uint private totalPrice;
    bool private lottoOn; // 仍然可以投注
    // private:
    address [] firstPrizeWinners;
    address [] secondPrizeWinners;
    // public: the number of winners of every level prize and bonus for each level prize
    uint256 [6] public countResults = [uint256(0),0,0,0,0,0];
    //uint [6] public prizeForEachLevel = [uint256(0), 0, 300 ether, 200 ether, 10 ether, 5 ether];
    uint [6] public prizeForEachLevel = [uint256(0), 0, 4 ether, 3 ether, 2 ether, 1 ether];
    // 一注彩票
    struct Bet {
    uint[7] numbers; // 选取的号码: 0->red, 1~6->blue
    uint count; // buy count bets this time. 买了count注
    }
    constructor(string _date) public payable{
        // authority = _authority;
        authority = 0x4C02D8D6CF951E636642a21F43BBB46C7fBF9342;
        // taxAuthorities = 0x5E509908c1Ea98B2F4cBaDc255B82FF8648B6D3D;
        // charity =0xE7b740EBA3bD52983f09482f03D6bFbeAC45a90b;
        
        // require(msg.sender == authority, "You don't have the right to post a lottery"); // success
        prizePond = msg.value;
        date = _date;
        // todo using event
        lottoOn = true;
    }
    function bet(uint[7] numbers) public payable {// debugging done
        require(lottoOn == true, "The Lottery has been closed"); // ok
        require(msg.value >= 2 ether, "No enough money");
        // require(msg.value % 2 == 0 ether, "Please pay for a complete Lottery(2 ether/note)");
        if(bets[msg.sender].length == 0) { // haven't Bet
            users.push(msg.sender);
        }
        bets[msg.sender].push(Bet(numbers, msg.value/2 ether));
        totalPrice += msg.value;
    }
    /**
    * randomly generate winnerNumbers
    */
    function draw() public payable{
        require(msg.sender == authority, "You are not the deployer of this contract");
        //todo change to emit a event
        lottoOn = false;
        uint range = 32*15*15*15*15*15*15;
        uint random = rand(range);
        // red ball
        uint redBall = random%33+1;
        random = random/32;
        winnerNumbers[0] = redBall;
        for(uint j = 1; j < 7; j++) {
            uint blue = random%16 + 1; // generate first blue ball
            bool flag = true;
            while(true) {
                flag = true;
                for(uint k = 1; k < j; k++) {
                    if(winnerNumbers[k] == blue) {
                        flag = false;
                        blue = (blue+1)%16;
                        if(blue == 0)
                            blue += 1;
                    }
                }
                if(flag)
                    break;
            }
            winnerNumbers[j] = blue;
            random = random/15;
        }
        computeResults();
    }
    /**
    * get winnerNumber from outsider
    */
    function testDraw(uint[7] results) public payable{
        //todo change to emit a event
        require(msg.sender == authority);
        lottoOn = false;
        winnerNumbers = results;
        computeResults();
    }
    /**
    * compute the prize for each level prize
    */
    function computeResults() public payable{
        uint highLevelBonus = totalPrice / 2;
        uint toCharity = totalPrice / 20 * 7;
        // charity.transfer(toCharity);
        // count and give out lower level prize
        for(uint i = 0; i < users.length; i++) {
            for(uint j = 0; j < bets[users[i]].length; j++) {
                uint result = checkPriceLevel(bets[users[i]][j].numbers);
                if(result >= 3) {
                // send bonus to lowers2
                    if(result != 7) {
                        uint temp = prizeForEachLevel[result - 1];
                        users[i].transfer( temp * bets[users[i]][j].count );
                    }
                } else {
                // record winners for highers
                    if(result == 1) {
                        for(uint k_first = 1; k_first <= bets[users[i]][j].count;k_first++) {
                            firstPrizeWinners.push(users[i]);
                        }
                    }
                    else {
                        for(uint k_second = 1; k_second <= bets[users[i]][j].count; k_second++) {
                            secondPrizeWinners.push(users[i]);
                        }
                    }
                }
                if(result != 7)
                    countResults[result - 1]+= bets[users[i]][j].count;
            }
        }
        for(uint k = 2; k < 6; k++) {
            highLevelBonus -= prizeForEachLevel[k]*countResults[k];
        }
        // count first prize bonus
        if(countResults[0] != 0) {
            if(totalPrice < 100000000 ether) {
                prizeForEachLevel[0] = uint(highLevelBonus * 3/4) + prizePond;
            } else {
                prizeForEachLevel[0] = uint(highLevelBonus * 11 / 20) + prizePond;
            }
            prizeForEachLevel[0] /= countResults[0];
            if(prizeForEachLevel[0] > 5000000 ether) {
                prizeForEachLevel[0] = 5000000 ether;
            }
            for(uint i_firstWinner = 0; i_firstWinner < firstPrizeWinners.length; i_firstWinner++) {
                address tempAddress = firstPrizeWinners[i_firstWinner];
                tempAddress.transfer(prizeForEachLevel[0]);
            }
        }
        if(countResults[1] != 0) {
            // count second prize bonus
            prizeForEachLevel[1] = highLevelBonus / 4 / countResults[1];
            for(uint i_secondWinner = 0; i_secondWinner < secondPrizeWinners.length;i_secondWinner++) {
                secondPrizeWinners[i_secondWinner].transfer(prizeForEachLevel[1]);
            }
        }
    }
    // function testTransfer () public {
    // address temp = firstPrizeWinners[0];
    // temp.transfer(firstPrizeBonus * 1 ether);
    // }
    function checkPriceLevel(uint[7] numbers) constant returns (uint){ // done
        require(lottoOn == false, "The Lotto haven't been drawn. ");
        bool redFlag = false;
        uint count = 0;// the number of winning blue ball
        if(numbers[0] == winnerNumbers[0]) { // win RedBall
            redFlag = true;
        }
        // todo compare array or hash of array
        // assume the blue balls are sorted in JS
        // uint i = 1;
        for(uint i = 1; i < 7; i++) {
            for(uint j = 1; j < 7; j++) {
                if(numbers[i] == winnerNumbers[j]) {
                    count++;
                }
            }
        }
        if(redFlag && count == 6)
            return 1;
        else if(count == 6) {
            return 2;
        } else if(redFlag && count == 5) {
            return 3;
        }
        if(redFlag)
            count++;
        if(count == 5)
            return 4;
        else if(count == 4)
            return 5;
        else if(redFlag)
            return 6;
        return 7;
    }
    // make sure this contract can accept Ether
    function () payable public {
         revert();
    }
    
    function getResult() constant public returns (uint []) {
        // uint temp = 1;
        uint[] memory ans = new uint[](bets[msg.sender].length*8);
        ans[0] =  1;
        ans[6] = 8;
        // uint8 [] ans;
        // ans = [1,2,3,4,5];
        for(uint i = 0; i < bets[msg.sender].length; i++) {
        //     temp = 2;
            for(uint j = 0; j < 7; j++) {
                ans[i*8+j] = bets[msg.sender][i].numbers[j];
            }
            ans[i*8+7] = bets[msg.sender][i].count;
        }
        // temp = 3;
        return ans;
    }
    function rand(uint range) public view returns(uint) {
        uint randNouce = 0;
        uint random = uint(keccak256(now, msg.sender, randNouce));
        return random;
    }
    
    function getWinnerNumbers() constant public returns (uint[7]){
        return winnerNumbers;
    }
    
    function getUsers() constant returns (address[]) {
        return users;
    }
    
    function isAuthority() constant public returns (bool){
        return msg.sender == authority;
    }
    // just for debugging
    function getAuthority() constant returns (address){
        return authority;
    }
    
    function getFirstPrize() constant returns (uint) {
        return firstPrize;
    }
    
    function getState() constant returns (bool) {
        return lottoOn;
    }
    
}