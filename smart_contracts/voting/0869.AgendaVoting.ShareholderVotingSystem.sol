pragma solidity ^0.4.22;

/**
 * @title SafeMath
 * @dev   Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/*
*   @title  CompanyShares
*   @dev    Issue, buy, sell and transfer of stocks in a company
*/
contract CompanyShares {
    // to prevent some possible problems in handling integer data
    using SafeMath for uint256;
    
    mapping (address => uint256) shareholderToShares;
    mapping (address => bool) approvals;   // owner's approval of withdraw
    
    uint32      sharePrice;     // price per a stock
    address[]   shareholders;   // addresses of stockholders
    uint256     balance;        // to deposit some asset by owner
    address     owner;          // to save the owner of this contract
    
    /*  @dev check if the message sender is the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /*
    *   @dev    When deploy, this function is executed. 
    *           In real world, startup a company.
    */
    constructor(uint256 supply, uint32 _price) public {
        shareholders.push(msg.sender);
        shareholderToShares[msg.sender] = supply;
        sharePrice = _price;
        owner = msg.sender;
    }
    /*
    *   @dev    View the current status
    */
    function getShareholder(uint256 index) view public returns(address, uint256) {
        if (index >= shareholders.length) return (0, 0);
        return (shareholders[index], shareholderToShares[shareholders[index]]);
    }
    function getShareByAddress(address _address) view public returns(uint256) {
        return shareholderToShares[_address];
    }
    /*  @dev    The owner may deposit some for withdraw or etc. 
    */
    function deposit() public payable onlyOwner {
        balance = msg.value;
    }
	function getSharePrice() view public returns(uint32) {
        return sharePrice;
    }
    function getBalance() view public returns(uint256) {
        return balance;
    }
    /*
    *   @dev    Anybody can buy stocks from the original owner
    */
    function buyShares(uint256 amount) public payable {  // amount:wei
        require(shareholderToShares[owner] >= amount);
        require(msg.value >= amount.mul(sharePrice));
        owner.transfer(amount.mul(sharePrice));
        shareholderToShares[owner] = shareholderToShares[owner].sub(amount);
        
        //check if there is duplicate address
        for (uint i = 0; i < shareholders.length; i++)
            if (shareholders[i] == msg.sender) break;
        if (i == shareholders.length) shareholders.push(msg.sender);
        
        shareholderToShares[msg.sender] = 
            shareholderToShares[msg.sender].add(amount);
    }
    /*  @dev The owner only can approve the withdraw of purchasing stocks
    */
    function approve(address _to, bool yesNo) public onlyOwner {
        approvals[_to] = yesNo;
    } 
    /*  @dev    The buyer can cancel its buying of stocks if owner allows it
    */
    function withdraw() public { 
        require(approvals[msg.sender]);
        uint256 amount = shareholderToShares[msg.sender].mul(sharePrice);
        if (balance < amount) return;
        shareholderToShares[owner] = 
            shareholderToShares[owner].add(shareholderToShares[msg.sender]);
        msg.sender.transfer(amount);
        balance = balance.sub(amount);
        shareholderToShares[msg.sender] = 0;
    }
    /*  @dev    The owner can change the stock price anytime.
    */
    function changePriceOfShare(uint32 _price) public onlyOwner {
        sharePrice = _price;
    }
    /*
    *   @dev    shareholders can transfer their stocks to others
    *           without any condition
    */
    function transferShares(address _to, uint256 shares) public {
        if (shareholderToShares[msg.sender] < shares) return;
        shareholderToShares[_to] = shareholderToShares[_to].add(shares);
        shareholderToShares[msg.sender] = shareholderToShares[msg.sender].sub(shares);
        //check if there is duplicate address
        for (uint i = 0; i < shareholders.length; i++)
            if (shareholders[i] == _to) break;
        if (i == shareholders.length) shareholders.push(_to);
    }
}
/*
*   @title  Voting on Agenda
*   @dev    Voting system to handle a agender suggested in a stockholder's meeting
*           and save the minutes which describes the shareholder's meeting
*/
contract VotingOnAgenda is CompanyShares {
    // to prevent some possible problems in handling integer data
    using SafeMath for uint32;  
    using SafeMath for uint256; 
     
    event AgendaSetup(string agenda, uint256 startTime, uint256 endTime, uint noOfOptions);
    event AgendaVote(address voter, uint256 votingTime, uint256 sharesToVote);
    event TransferVotingShares(address to, uint256 shares, uint256 time);
    
    mapping (address => uint256) votingShares;
    mapping (uint8 => uint256)   agendaVotes;
	
    address[]   actualVoters;   // addresses who have voting rights
	
    // Some agenda to be discussed and decided by voting in the meeting
    struct Agenda {
        string  contents;  // contains the subject to be decided and its options 
        uint256 startTime;
        uint256 endTime;
        uint8   noOfOptions;
    }
    Agenda agenda; // at present it is one but it can be array if there are many agenda
    
    struct Document {
        string hash;
        uint256 dateAdded;
    }
    Document[] private documents;
	
	// describes the time to be valid for voting
    modifier withinDeadLine () {
        require(agenda.startTime <= now);
        require(agenda.endTime >= now);
        _;
    }
    // stockholders or someone who are committed by the stockholders
    modifier onlyShareholders() {
        require(votingShares[msg.sender] > 0);
        _;
    }
	// to inherit from ComapayShares constructor
	constructor(uint256 supply, uint32 price) CompanyShares(supply, price) public {}
	
    /*
    *   @dev Starting the processing of a agenda, set up inital data
    */
    function registerAgenda(string _agendaContents, uint256 duration, uint8 _noOfOptions) 
												public onlyOwner {
         // clear the information of voters and their shares and previous voting result
         for (uint i = 0; i < actualVoters.length; i++) {
             votingShares[actualVoters[i]] = 0;
         }
         actualVoters.length = 0;
         for (uint8 j = 1; j <= agenda.noOfOptions; j++)  agendaVotes[j] = 0;
         
         agenda.contents = _agendaContents;
         agenda.startTime = now;
         agenda.endTime = now + duration*3600*1000;  // duration is hour
         agenda.noOfOptions = _noOfOptions;  	// items to be slected by the voters
         
         // Copy from shareholderToShares to votingShares
         // Initially, the number of shares equals to the number of voting share
         for (i = 0; i < shareholders.length; i++) {
             votingShares[shareholders[i]] = shareholderToShares[shareholders[i]];
			 actualVoters.push(shareholders[i]);
         }
         for (j = 1; j <= _noOfOptions; j++)  agendaVotes[j] = 0;
         
         emit AgendaSetup(_agendaContents, agenda.startTime, agenda.endTime, _noOfOptions);
    }
    /*
    *  @dev Below functions are for only viewing the current status
    */
    function getAgendaVotingVotes(uint8 index) view public returns (uint256) {
        return agendaVotes[index];
    }
    function getAgendaContents() public view returns(string) {
        return agenda.contents;
    }
    function getStartTime() public view returns(uint256) {
        return agenda.startTime;
    }
    function getEndTime() public view returns(uint256) {
        return agenda.endTime;
    }
	function getActualVoter(uint index) public view returns(address, uint256) {
		if (index >= actualVoters.length) return (0, 0);
		return (actualVoters[index], votingShares[actualVoters[index]]);
	}
    /*
    *  @dev Anybody can participate in the voting if he or she has some 
    *       voting shares
    */
    function vote(uint8 index, uint32 sharesToVote) public onlyShareholders withinDeadLine {
        if (index <= 0 || index > agenda.noOfOptions) return;
        if (sharesToVote > votingShares[msg.sender]) return;
        agendaVotes[index] = agendaVotes[index].add(sharesToVote);
        votingShares[msg.sender] = votingShares[msg.sender].sub(sharesToVote);
        emit AgendaVote(msg.sender, now, sharesToVote);
    }
    /*
    *  @dev Shareholders can yield their voting shares to other address
    *       valid only if doing between startTime and endTime
    */
    function transferVotingShares(address _to, uint256 shares) public withinDeadLine {
        if (votingShares[msg.sender] < shares) return;
        votingShares[_to] = votingShares[_to].add(shares);
        votingShares[msg.sender] = votingShares[msg.sender].sub(shares);
		for (uint i = 0; i < actualVoters.length; i++)
			if(actualVoters[i] == _to) break;
		if(i == actualVoters.length) actualVoters.push(_to);
		
        emit TransferVotingShares(_to, shares, now);
    }
    /*
    *   @dev Save the minutes regarding Shareholders' meeting in IPFS
    *   and it can be read by anybody 
	*   It is to prevent any possible disputes among shareholders
    */
    function saveDocument(string hash) public onlyOwner {
        documents.push(Document(hash, now));
    }
    function getDocumentsCount() public view returns (uint length) {
        length = documents.length;
    }
    function getDocuments(uint index) public view returns(string, uint) { 
        Document memory document = documents[index];
        return (document.hash, document.dateAdded);
    }
}