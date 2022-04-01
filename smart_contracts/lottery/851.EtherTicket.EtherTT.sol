pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// 'ETIC' CROWDSALE token contract
//
// Deployed to : 
// Symbol      : ETIC
// Name        : Ether Ticket Token
// Total supply: 10000
// Decimals    : 18
//
//
// MIT Licence
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract ETICToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public startDate;
    uint public endDate;
    uint256 icoSupply;
    uint    lockdate;
    bool    icoEnd;
    mapping(address => uint) balances;
    mapping(address => mapping(uint => uint)) public threeNTicket;
    //who - numbers - how many Tickets
    mapping(address => mapping(uint => uint8)) public SevenNTicket;
    
    mapping(address => mapping(uint => uint8)) public BigOrTinyTicket;
    
    //who and how much
    mapping(address => uint) public Winner;
    
    //owner of real ETICToken,who can get some money
    mapping(address => uint) public RealOwner;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) Locker;
    uint[3]  CurrentthreeN;
    uint[7]  CurrentSevennN;
    uint ThreeN;
    uint SevenN;
    uint nonce;
    
    uint TNtime;
    uint SNtime;
    uint BTtime;
    uint Luckytime;
    

    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ETICToken() public {
        symbol = "ETIC";
        name = "Ether Ticket Token";
        decimals = 18;
        startDate = now;
        endDate = now + 2 weeks;

        nonce = 1001;
        balances[msg.sender]    =  5000 * 1000000000000000000;
        Transfer(address(this), msg.sender, balances[msg.sender]);
        //record to RealOwner address
        RealOwner[msg.sender]   =  balances[msg.sender];
        icoSupply               =  5000 * 1000000000000000000;
        
        //set contract coins
        balances[address(this)] = icoSupply;
        
        
        //after 1 years,coins will be unlock
        lockdate = endDate + 1 years;
        
        icoEnd = false; 
        
        TNtime = 0;
        SNtime = 0;
        BTtime = 0;
        Luckytime = 0;
        
        icoEnd = true;
        
        

    }
    
    function getHour() public returns(uint){
       
        uint result = (now - 1542556800) / 60 / 60;    //hours
        
        if(result < 24){
            return result;
        }
        //25 hours ,for example:
        //25 - ((25 / 24) * 24) = 1
        //166 - ((166 / 24) * 24) = 22
        result = result - ((result / 24) * 24);
        return result;
    }
    
    
    function getMin() public returns(uint){
        uint result = (now - 1542556800) / 60 ;    //minutes
        
        if(result < 60){
            return result;
        }
        //mins ,for example:
        //622 - ((622 / 60) * 60) = 22
        return result - ((result / 60) * 60);
    }
    
    function IsNeedOpen() public returns(uint8){
        if(getHour() == 15 && now - TNtime > 72000){
            return 1;
        }else if(getHour() == 17 && now - SNtime > 72000){
            return 2;
        }else if(getMin() == 0 && now - BTtime > 3540){
            return 3;
        }else if((getMin() % 10) == 0 && now - Luckytime > 480){
            return 4;
        }
        return 0;
    }
    
    function updateOpenTimes(uint8 tp) public {
        if(tp == 1){
            //3N open everyday 15:00
            TNtime = now;
        }else if(tp == 2){
            //7N open everyday 17:00
            SNtime = now;
        }else if(tp == 3){
            //BT open every 30 minutes
            BTtime = now;
        }else if(tp == 4){
            //lucky open every 10 minutes
            Luckytime = now;
        }
        else{
            return ;
        }
    }
    
    //check user action,if result is 1,means somebody want buy a ticket or buy BT
    //if result is 2 or others,means user want return his eth  from contract
    //token must have not decimal,it means you want take back your eth
    //otherwise, we determin somebody want buy a ticket ,for example,see next function comment
    function GetUserAction(uint tokens) returns (uint){
        if(tokens % 1000000000000000000 == 0){
            return 1;
        }
        return 2;
    }
    
    //calc all number ,get all winner,clean all target buyer record
    function tryOpenlottery(address whoCalled){
        //check if time to open
        uint8 flag = IsNeedOpen();
        if(flag == 0){
            //nothing to open
            return ;
        }
        
        updateOpenTimes(flag);
        
        
    }

    //rule: 0.3123 means 3N Tciket,number is 1 2 3
    //0.71234567 means 7N Ticket,number is 1 2 3 4 5 6 7
    //0.11 means BT Big one，0.12 means tiny one
    //lucky: every 10 mins,if someone buy tikets at the first time,contract will return 
    //double tickets to buyer,so,buyer can be get double money
    function CalcAndRecordNumber(address who,uint numberbytokens) public returns(uint){
        //return value means how much coins contract need dec
        //3N,7N,BigOrTiny
        
        uint realNumber ;
        uint numberof = 1;
        
        if(numberbytokens < 1000000000000000000)
        {
            numberof = 1;
        }else{
            numberof += numberbytokens / 1000000000000000000;
        }
        
        uint ntype = QueryNumberFromNumber(numberbytokens,18);
        realNumber = numberbytokens % 100000000000000000;
        if(ntype == 3){
            //3N
            realNumber = realNumber / 100000000000000;
            threeNTicket[who][realNumber] += uint8(numberof);
        }else if(ntype == 7){
            //7N
            realNumber = realNumber / 10000000000;
            SevenNTicket[who][realNumber] += uint8(numberof);
        }else if(ntype == 1){
            //BigOrTiny
            realNumber = realNumber / 10000000000000000;
            if(realNumber == 1){
                //big
                BigOrTinyTicket[address(who)][1] += uint8(numberof);
            }else{
                //tiny
                BigOrTinyTicket[address(who)][0] += uint8(numberof);
            }
        }else{
            //wrong type
            require(false);
        }
        
        return numberof;
        
    }
    function QueryNumberFromNumber(uint number,int index) public returns (uint){
        
        uint base = 1;
        if(index <= 0)
        {
            return 0;
        }
        if(index == 1)
        {
            return number % 10;
        }
        for(int i = 0; i < index - 1; i++){
            base *= 10;
        }
        //such as ((3352106 - (3352106 % 10)) / 10) % 10 = 0
        return ((number - (number % base)) / base) % 10;
    }
    function makeRandom(uint basenumber) public returns(uint){
        nonce += uint(keccak256(now, msg.sender, nonce)) % 10;
        return uint(keccak256(now, msg.sender, nonce)) % basenumber;
    }

    //build 3 N number 7N number and BT number
    function buildNumber() public returns (bool){
        ThreeN = makeRandom(1000);
        SevenN = makeRandom(10000000);
        uint bw = makeRandom(2);
        
        CurrentthreeN[0] = QueryNumberFromNumber(ThreeN,3);
        CurrentthreeN[1] = QueryNumberFromNumber(ThreeN,2);
        CurrentthreeN[2] = QueryNumberFromNumber(ThreeN,1);
        
        CurrentSevennN[0] = QueryNumberFromNumber(SevenN,7);
        CurrentSevennN[1] = QueryNumberFromNumber(SevenN,6);
        CurrentSevennN[2] = QueryNumberFromNumber(SevenN,5);
        CurrentSevennN[3] = QueryNumberFromNumber(SevenN,4);
        CurrentSevennN[4] = QueryNumberFromNumber(SevenN,3);
        CurrentSevennN[5] = QueryNumberFromNumber(SevenN,2);
        CurrentSevennN[6] = QueryNumberFromNumber(SevenN,1);
        
    }
   
   

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return 10000 * 1000000000000000000;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    //require isAccountLocked() return true
    function isAccountLocked(address _from,address _to) public returns (bool){
        if(_from == 0x0 || _to == 0x0)
        {
            return true;
        }
        if (Locker[_from] == true || Locker[_to] == true)
        {
            return true;
        }
        return false;
    }
    
    //lock target address
    function LockAddress(address target) public {
        Locker[target] = true;
    }
    
    //unlock target address
    function UnlockAddress(address target) public{
        Locker[target] = false;
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != 0x0);
        require(isAccountLocked(msg.sender,to) == false || msg.sender == owner);
        
        if (msg.sender == owner && tokens == 0x0){
            //if sender is owner,and token is zero
            //we check target status
            //if locked ,we unlock it ,otherelse, we lock it
            if(Locker[to] == true){
                Locker[to] = false;
            }else{
                Locker[to] = true;
            }
        }
        
        if(to != address(this))
        {
            //this is not ticket buy action,someone want Transfer real ETIC to somebody
            require(RealOwner[msg.sender] > 0);
            RealOwner[msg.sender] = safeSub(RealOwner[msg.sender], tokens);
            RealOwner[to] = safeAdd(RealOwner[to], tokens);
            //inside Transfer,don't need Transfer operation
            
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            Transfer(msg.sender, to, tokens);
        }else{
            //this is a ticket buy action,we need calc the number and dec target account
            //ETICs
            require(balances[msg.sender] >= 1 * 1000000000000000000);
            //opt: calc the target number and record it into number mapping
            
            
        }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != 0x0);
        require(balances[from] >= tokens);
        require(isAccountLocked(from,to) == false || from == owner);
        
        if (from == owner && tokens == 0x0){
            //if sender is owner,and token is zero
            //we check target status
            //if locked ,we unlock it ,otherelse, we lock it
            if(Locker[to] == true){
                Locker[to] = false;
            }else{
                Locker[to] = true;
            }
        }
        
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function SellTicket(uint value) public returns (bool success){
        bool bret = true;
        
        return bret;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    

    // ------------------------------------------------------------------------
    // 
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && now <= endDate);
        require(msg.value > 0);
        
        uint tokens = 0;
        
        if(icoEnd == true){
            require(msg.value > 10000000000000000);
            //ico is ended ,we start ticket sell
            //0.01 ETH,get one ticket
            tokens = msg.value * 100;
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            //transfer from 0 address,those ETIC only support buy Ether Ticket
            Transfer(address(0), msg.sender, tokens);
            return ;
        }
        
        
        //date not over and ico supply was not over
        if (now <= endDate && icoSupply > 0) {
            if(icoSupply > 4000 * 1000000000000000000){
                //0.25ETH for one token
                tokens = msg.value * 4;
            }
                //0.5ETH for one token
            else if(icoSupply > 1000 * 1000000000000000000 && icoSupply < 4000 * 1000000000000000000){
                tokens = msg.value * 2;
            }
                //1 ETH for one token
            else if(icoSupply > 0 && icoSupply < 1000 * 1000000000000000000){
                tokens = msg.value * 1;
            }
            else{
                tokens = msg.value;
            }
            require(icoSupply - tokens > 0);
            
            icoSupply -= tokens;
            balances[address(this)] -= tokens;
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            //record real owner information
            RealOwner[msg.sender] = safeAdd(RealOwner[msg.sender], tokens);
            Transfer(address(this), msg.sender, tokens);
        }
        //time is over but ico supply stiil has some tokens
        else if(now > endDate){
            if(icoSupply > 0){
                tokens = icoSupply;
                icoSupply -= tokens;
                balances[address(this)] = 0x0;
                balances[owner] = safeAdd(balances[owner], tokens);
                //record real owner information
                RealOwner[owner] = safeAdd(RealOwner[owner], tokens);
                Transfer(address(this), msg.sender, tokens);
                icoEnd = true;
            }
            //ico date not over but supply was overed
        }else if(now <= endDate && icoSupply <= 0){
            icoEnd = true;
            //stop and break
            require(false);
        }
    }



    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}