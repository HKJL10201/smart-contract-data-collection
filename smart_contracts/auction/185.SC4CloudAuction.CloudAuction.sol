pragma solidity > 0.6.5;

/**
 * The CloudAuction contract manage the lifecycle of federated cloud auction.
 * ==========================================
 *  Title: Smart Contracts for Cloud Auction 
 *  Author: Zeshun Shi
 *  Email: z.shi2@uva.nl
 * ==========================================
 */
contract CloudAuction {

    uint public startTime;
    uint public setupEnd;
    uint public registeEnd;
    uint public biddingEnd;
    uint public revealEnd;
    uint public withdrawEnd;
    uint public serviceStart;
    uint public serviceEnd;

    uint public reservePrice;
    uint public unitWitnessFee = 1e17;  // To ensure each witness tell the truth, unitWitnessFee should weakly balanced with Epsilon * providerNumber.
    uint public Epsilon = 4;
    uint [] public revealedBids;
    uint [] public winnerBids;
    uint [] public loserBids;

    mapping(address => AuctionItem) public auctionItemStructs;
    mapping(address => Bid) public bidStructs;
    mapping(address => uint) refund;   
    mapping(address => ContractInfo) public SLAContractPool;
    mapping(address => Witness) public witnessPool;
    mapping (address => bytes32[]) sealedMessageArray;
    mapping (address => uint[]) public revealedMessageArray;
    mapping (address => uint) public witnessFee;
    mapping (address => bool) public SLAViolated;
    mapping (address => Bidder) public providerPool;


    address [] public bidderAddresses;
    address payable [] public revealedBidders;
    address payable [] public winnerBidders;
    address payable [] public loserBidders;
    address [] public SLAContractAddresses;
    address [] public witnessAddrs;    ////the address pool of witnesses
    address payable [] public revealedWitnesses; 
    address [] public SLAViolatedAddresses;
    address payable [] public customerAddresses;
    address [] public providerAddrs;    ////the address pool of providers, which is used for register new providers in the auction

    struct Bidder {
        uint index; // the id of the provider in the address pool
        bool registered;    ///true: this provider has registered     
    }

    struct Bid {
        string providerName;
        bytes32 sealedBid;
        uint witnessFee;
    }

    struct AuctionItem {
        string cutomerName;
        bytes32 sealedReservePrice;
        string auctionDetails;
        uint witnessFee; 
        uint8 providerNumber;
        uint8 witnessNumber;
    }

    struct ContractInfo {
        uint index; // the id of the SLA contract in the address pool
        uint serviceFee; // the service fee should be the bidding price
        bool accepted; // true: this contract has been accepted
    }
    
    struct Witness {
        uint index;         ///the index of the witness in the address pool, if it is registered
        bool registered;    ///true: this witness has registered.
        address[] SLAContracts;    ////the address of SLA contract
    }

    // this is to illustrate the state machine of the CloudAuction contract
    enum State { Ready, Initialized, Pending, Settled, Violated, Successful, Canceled }
    State public AuctionState;


    // this is to log event that _who modified the Auction state to _newstate at time stamp _time
    event AuctionStateModified(address indexed _who, uint _time, State _newstate);
    // this is to log event that _who generate the SLA contract _contractAddr at time stamp _time
    event SLAContractsGenerated(address indexed _who, uint _time, address[] _contractAddr);


    modifier checkTimeBefore(uint _time) 
    {   
        require(now < _time, "The time is not before the time point");
        _;          
    }
    modifier checkTimeAfter(uint _time)
    {    
        require(now > _time, "The time is not after the time point");
        _;          
    }
    modifier checkState(State _state){
        require(AuctionState == _state, "The aution is not in the right state");
        _;          
    }
    modifier checkReset(){
        require(AuctionState == State.Violated || AuctionState == State.Successful || AuctionState == State.Successful, "The aution is not ready to reset");
        _;          
    }   
    modifier checkProvider(address _user) 
    {    
        require(providerPool[_user].registered == true, "The current user is not a registered provider");
        _;          
    }
    modifier checkCustomer(address payable _user) { 
        require (customerAddresses[0] == _user, "The current user is not the correct customer"); 
        _;          
    }
    modifier checkWitness(address _user) 
    {    
        require(witnessPool[_user].registered == true, "The current user is not a registered witness");
        _;          
    }

    
    /**
     * Customer Interface:
     * This is constructor for someone (Normally the customer) to initiate the time durations for AuctionManagement contract
     * */
    constructor(uint _setupTime, uint _registeTime, uint _biddingTime, uint _revealTime, uint _withdrawTime, uint _serviceTime) 
        public 
    {
        require (_setupTime > 0);
        require (_registeTime > 0);
        require (_biddingTime > 0);
        require (_revealTime > 0);
        require (_withdrawTime > 0);
        require (_serviceTime > 0);
     
        startTime = now;
        setupEnd = startTime + _setupTime;
        registeEnd = setupEnd + _registeTime;
        biddingEnd = registeEnd + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        withdrawEnd = revealEnd + _withdrawTime;

        serviceStart = withdrawEnd + 1 days;
        serviceEnd = serviceStart + _serviceTime;

        AuctionState = State.Ready;
        emit AuctionStateModified(msg.sender, now, State.Ready);
    }
    
    /**
     * Customer Interface:
     * This is for customer to 1) setup the auction, 2) publish the auction details, and 3) prepay the witnessfee
     * */
    function setupAuction (string memory _customerName, string memory _auctionDetails, bytes32 _sealedReservePrice, uint8 _providerNumber, uint8 _witnessNumber) 
        public
        payable
        checkState(State.Ready)
        checkTimeAfter(startTime)
        checkTimeBefore(setupEnd)
        returns(bool setupAuctionSuccess)
    {
        require (_sealedReservePrice.length != 0 && bytes(_auctionDetails).length > 0);
        require (customerAddresses.length == 0);
        require (msg.value >=  (_witnessNumber * unitWitnessFee) / 2 );
        auctionItemStructs[msg.sender].cutomerName = _customerName;
        auctionItemStructs[msg.sender].sealedReservePrice = _sealedReservePrice;
        auctionItemStructs[msg.sender].auctionDetails = _auctionDetails;
        auctionItemStructs[msg.sender].providerNumber = _providerNumber;
        auctionItemStructs[msg.sender].witnessNumber = _witnessNumber;
        auctionItemStructs[msg.sender].witnessFee = msg.value;
        customerAddresses.push(msg.sender);
        return true;        
    }
    
    /**
     * Provider Interface:
     * This is for normal user register as providers(bidders) to participant the auction
     * */
    function bidderRegister () 
        public
        checkState(State.Ready)
        checkTimeAfter(setupEnd)
        checkTimeBefore(registeEnd)
        returns(bool registerSuccess) 
    {
        require (providerPool[msg.sender].registered == false);
        providerPool[msg.sender].index = providerAddrs.length;
        providerPool[msg.sender].registered = true;
        providerAddrs.push(msg.sender);
        return true;
    }

    /**
     * Customer Interface:
     * This is for customer to check the whether the registered provider number is enough for the auction and set the auction state
     * */
    function checkProviderNumber () 
        public
        checkCustomer(msg.sender)
        checkTimeAfter(registeEnd)
    {
        if (providerAddrs.length >= auctionItemStructs[customerAddresses[0]].providerNumber){
            AuctionState = State.Initialized;
            emit AuctionStateModified(msg.sender, now, State.Initialized);
        } else {
            AuctionState = State.Canceled;
            emit AuctionStateModified(msg.sender, now, State.Canceled);
        }
    }

    /**
     * Provider Interface:
     * This is for registered providers to 1) submit sealed bids and 2) prepay the witness fee
     * */
    function submitBids(string memory _providerName, bytes32 _sealedBid) 
        public
        payable
        checkState(State.Initialized)
        checkTimeAfter(registeEnd)
        checkTimeBefore(biddingEnd)
        checkProvider(msg.sender)
        returns(bool submitSuccess)
    {
        require (_sealedBid.length != 0 && bytes(_providerName).length > 0);   
        require (bidderAddresses.length <= 20);
        require (msg.value >=  (auctionItemStructs[customerAddresses[0]].witnessNumber * unitWitnessFee) / (2 * auctionItemStructs[customerAddresses[0]].providerNumber) );
        bidStructs[msg.sender].sealedBid = _sealedBid;
        bidStructs[msg.sender].providerName = _providerName;
        bidStructs[msg.sender].witnessFee = msg.value;
        bidderAddresses.push(msg.sender);
        return true;
    }

    /**
     * Customer Interface:
     * This is for customer to reveal the reserve price
     * */
    function revealReservePrice (string memory _customerName, uint _reservePrice, uint _customerKey)
        public
        payable
        checkState(State.Initialized)
        checkTimeAfter(biddingEnd)
        checkTimeBefore(revealEnd)
        checkCustomer(msg.sender)
        returns(uint)
    {
        require (_reservePrice > 0 && _customerKey != 0);
        require (keccak256(abi.encodePacked(auctionItemStructs[msg.sender].cutomerName)) == keccak256(abi.encodePacked(_customerName)));
        require (bidderAddresses.length >= auctionItemStructs[customerAddresses[0]].providerNumber && customerAddresses.length == 1);
        if (keccak256(abi.encodePacked(_reservePrice, _customerKey)) == auctionItemStructs[msg.sender].sealedReservePrice){
            reservePrice = _reservePrice;
        }
        return reservePrice;
    }
    
    /**
     * Provider Interface:
     * This is for registered providers(who submitted the sealed bid) to reveal the bid
     * */
    function revealBids (string memory _providerName, uint _bid, uint _providerKey)
        public
        payable
        checkState(State.Initialized)
        checkTimeAfter(biddingEnd)
        checkTimeBefore(revealEnd)
        checkProvider(msg.sender)
    {
        require (_bid > 0 && _providerKey != 0);
        require (keccak256(abi.encodePacked(bidStructs[msg.sender].providerName)) == keccak256(abi.encodePacked(_providerName)));
        if (keccak256(abi.encodePacked(_bid, _providerKey)) == bidStructs[msg.sender].sealedBid){
            // revealedBids[msg.sender] = _bid;
            revealedBidders.push(msg.sender);
            revealedBids.push(_bid);
        }
    }

    /**
     * Customer Interface:
     * This is for customer to 1) sort the bids by ascending 2) select k-th providers to form a federated cloud servcie
     * */        
    function placeBids () 
        public
        checkState(State.Initialized)
        checkTimeAfter(revealEnd)
        checkTimeBefore(withdrawEnd)
        checkCustomer(msg.sender)
        returns(address payable [] memory, address payable [] memory)
    {

        require (revealedBidders.length >= auctionItemStructs[customerAddresses[0]].providerNumber);
        bool exchanged; 
        for (uint i=0; i < revealedBids.length - 1; i++) {
            exchanged = false;
            for (uint j =0; j < revealedBids.length- i - 1; j++){
                if (revealedBids[j] > revealedBids[j+1]){
                    (revealedBids[j], revealedBids[j+1]) = (revealedBids[j+1], revealedBids[j]);
                    (revealedBidders[j], revealedBidders[j+1]) = (revealedBidders[j+1], revealedBidders[j]);
                    exchanged = true;
                }
            }
                if(exchanged==false) break;
        }

        uint sumBids;
        for(uint i=0; i < auctionItemStructs[customerAddresses[0]].providerNumber; i++){
            sumBids += revealedBids[i];
        }
        
        for (uint i=0; i < revealedBidders.length; i++) {
            if( i< auctionItemStructs[customerAddresses[0]].providerNumber && sumBids <= reservePrice) {
                winnerBids.push() = revealedBids[i];
                winnerBidders.push() = revealedBidders[i];
            } else if( i >= auctionItemStructs[customerAddresses[0]].providerNumber && sumBids <= reservePrice ){
                loserBids.push() = revealedBids[i];
                loserBidders.push() = revealedBidders[i];
            } else if( sumBids > reservePrice ){
                loserBids.push() = revealedBids[i];
                loserBidders.push() = revealedBidders[i];
            }
        }
        if (winnerBidders.length == auctionItemStructs[customerAddresses[0]].providerNumber){
            AuctionState = State.Pending;
            emit AuctionStateModified(msg.sender, now, State.Pending);
        } else if (winnerBidders.length == 0){
            AuctionState = State.Canceled;
            emit AuctionStateModified(msg.sender, now, State.Canceled);
        }
        return (winnerBidders,loserBidders);
    }

    /**
     * Provider Interface:
     * This is for loser providers to withdraw the witness fee
     * */
    function providerWithdrawWitnessFee()
        public  
        checkTimeAfter(revealEnd)
        checkTimeBefore(withdrawEnd)
        checkProvider(msg.sender)
        returns(bool withdrawSuccess)
    { 
        require (bidStructs[msg.sender].witnessFee > 0);
        require (loserBidders.length != 0);
        for (uint i=0; i < loserBidders.length; i++) {
            if (loserBidders[i] == msg.sender){
            refund[msg.sender] = bidStructs[msg.sender].witnessFee;
            msg.sender.transfer(refund[msg.sender]);
            bidStructs[msg.sender].witnessFee = 0;
            return true;
            }
        }        
    }

    /**
     * Customer Interface:
     * This is for customer to withdraw the witness fee, if the auction is failed (3 situations)
     * */
    function customerWithdrawWitnessFee()
        public  
        checkState(State.Canceled)
        checkTimeAfter(revealEnd)
        checkTimeBefore(withdrawEnd)
        checkCustomer(msg.sender)
        returns(bool withdrawSuccess)
    {
        require (auctionItemStructs[msg.sender].witnessFee > 0);
        if (winnerBidders.length == 0) {
            refund[msg.sender] = auctionItemStructs[msg.sender].witnessFee;
            msg.sender.transfer(refund[msg.sender]);
            auctionItemStructs[msg.sender].witnessFee = 0;         
        }
        return true;
    }

    /**
     * Customer Interface:
     * This is for customer to 1) generate the SLA contracts for winner providers and 2) prepay the total service fee
     * */
    function genSLAContract() 
        public
        payable
        checkState(State.Pending)
        checkTimeBefore(serviceStart)
        checkCustomer(msg.sender)
        returns(address[] memory)
        
    {
        require ( winnerBidders.length > 0);   
        for (uint i=0; i < winnerBidders.length; i++) {
            address newSLAContract = address (new CloudSLA(this, winnerBidders[i], msg.sender, auctionItemStructs[msg.sender].auctionDetails, winnerBids[i]));
            SLAContractPool[newSLAContract].index = SLAContractAddresses.length;
            SLAContractPool[newSLAContract].serviceFee = winnerBids[i];
            SLAContractAddresses.push(newSLAContract);
        }
        uint totalBids;
        for (uint i=0; i < winnerBids.length; i++) {
            totalBids += winnerBids[i];
        }
        require (msg.value == totalBids);

        if (SLAContractAddresses.length == winnerBidders.length){
            emit SLAContractsGenerated(msg.sender, now, SLAContractAddresses);
            return SLAContractAddresses;
        }
    }

    /**
     * Provider Interface:
     * This is for Providers to accept the SLA contracts
     * */
    function acceptSLA() 
        public 
        payable 
        checkState(State.Pending)
        checkTimeBefore(serviceStart)
        checkProvider(msg.sender)
    {   
        require (SLAContractAddresses.length == winnerBidders.length);   
        for (uint i=0; i < winnerBidders.length; i++) {
            if (winnerBidders[i] == msg.sender){
            SLAContractPool[SLAContractAddresses[i]].accepted = true;
            }
        }
    }

    /**
     * Witness Interface:
     * This is for normal users register as witnesses to monitor the federated Cloud service
     * */
    function witnessRegister()
        public
        checkState(State.Pending)
        checkTimeAfter(revealEnd)
        checkTimeBefore(serviceStart)
        returns(bool registerSuccess)
    {
        require (witnessAddrs.length <= 100);
        require (witnessPool[msg.sender].registered == false);
        witnessPool[msg.sender].index = witnessAddrs.length;
        witnessPool[msg.sender].registered = true;
        witnessPool[msg.sender].SLAContracts = SLAContractAddresses;
        witnessAddrs.push(msg.sender);
        return true;
    }

    /**
     * Customer Interface:
     * This is for customer to check the whether the registered witnesses number is enough && all SLAs has been signed 
     * */
    function checkAuctionSettled () 
        public
        checkState(State.Pending)
        checkCustomer(msg.sender)
    {   
        uint counter;
        for (uint i=0; i < SLAContractAddresses.length; i++) {
            if (SLAContractPool[SLAContractAddresses[i]].accepted = true) {
                counter++;
            }
        }   
        if (witnessAddrs.length >= auctionItemStructs[customerAddresses[0]].witnessNumber && counter == SLAContractAddresses.length){
            AuctionState = State.Settled;
            emit AuctionStateModified(msg.sender, now, State.Settled);
        } else {
            AuctionState = State.Canceled;
            emit AuctionStateModified(msg.sender, now, State.Canceled);
        }
    }

    /**
     * Witness Interface:
     * This is for registered witnesses to submit the (sealed) monitoring messages array for different SLAs in the federated cloud service
     * */
    function submitMessages(bytes32[] memory _sealedMessage) 
        public
        payable
        checkState(State.Settled)
        checkTimeAfter(serviceEnd)
        checkWitness(msg.sender)
        returns(bool reportSuccess)
    {   
        require (witnessPool[msg.sender].registered = true);       
        require (_sealedMessage.length == auctionItemStructs[customerAddresses[0]].providerNumber);   
        sealedMessageArray[msg.sender] = _sealedMessage;
        return true;
    }

    /**
     * Witness Interface:
     * This is for registered witnesses(who submitted the sealed messages) to reveal the message array
     * */
    function revealMessages (uint[] memory _message, uint _witnessKey)
        public
        payable
        checkState(State.Settled)
        checkTimeAfter(serviceEnd)
        checkWitness(msg.sender)
        returns(bool revealSuccess)
    {
        require (_message.length == auctionItemStructs[customerAddresses[0]].providerNumber && _witnessKey != 0);
        uint SLAsNumber;
        for (uint i=0; i < auctionItemStructs[customerAddresses[0]].providerNumber; i++) {
            // check all the monitoring messages (for k SLAs) in the rang 0-10.
            require (_message[i] >= 0 && _message[i] <= 10);
            if (keccak256(abi.encodePacked(_message[i], _witnessKey)) == sealedMessageArray[msg.sender][i]){
                SLAsNumber++;
            }
        }
        // check all the monitoring messages(for k SLAs) in the array reveled successfully.
        if (SLAsNumber == auctionItemStructs[customerAddresses[0]].providerNumber) {
            revealedMessageArray[msg.sender] = _message;
            revealedWitnesses.push(msg.sender);
            return true;
        } else if (SLAsNumber < auctionItemStructs[customerAddresses[0]].providerNumber) {
            return false;
        }
    }

    /**
     * Customer Interface:
     * This is for customer to calculate the wisness fee for all the witnesses based on their report result
     * */ 
    function calculateWitnessFee ()
        public
        checkState(State.Settled)
        checkTimeAfter(serviceEnd)
        checkCustomer(msg.sender)
        returns(bool calculateSuccess)
    {

        require (revealedWitnesses.length == auctionItemStructs[customerAddresses[0]].witnessNumber);
        
        for (uint i=0; i < revealedWitnesses.length; i++) {
            uint accumulator = 0;
            for (uint j=0; j < auctionItemStructs[customerAddresses[0]].providerNumber; j++) {
                for (uint k=0; k < revealedWitnesses.length; k++) {
                    // here need to check the divide accuracy of solidity version
                    accumulator += (revealedMessageArray[revealedWitnesses[i]][j] - revealedMessageArray[revealedWitnesses[k]][j]) ** 2;
                }
            }
            witnessFee[revealedWitnesses[i]] = unitWitnessFee - accumulator * Epsilon / (revealedWitnesses.length - 1);
        }
        return true;
    }

    /**
     * Witness Interface:
     * This is for registered witnesses to withdraw the witness fee (if the message array is revealed successfully)
     * */ 
    function witnessWithdraw()
        public
        checkState(State.Settled)
        checkTimeAfter(serviceEnd)
        checkWitness(msg.sender)
        returns(bool withdrawSuccess)
    {
        require(witnessFee[msg.sender] > 0);
        msg.sender.transfer(witnessFee[msg.sender]);
        witnessFee[msg.sender] = 0;
        return true;
    }

    /**
     * Customer Interface:
     * This is for customer to check the SLA violation result and place the service fee 
     * */ 
    function checkSLAViolation ()
        public
        payable
        checkState(State.Settled)
        checkTimeAfter(serviceEnd)
        checkCustomer(msg.sender)
        returns(bool checkSuccess)
    {   
        uint counter;
        for (uint j=0; j < SLAContractAddresses.length; j++) {
            for (uint i=0; i < revealedWitnesses.length; i++) {
                // The message space is [1,10], the mean is 5
                if (revealedMessageArray[revealedWitnesses[i]][j] > 5) {
                    counter ++; 
                }
            }
            if (counter > revealedWitnesses.length/2) {
                SLAViolated[SLAContractAddresses[j]] = true;
                SLAViolatedAddresses.push() = SLAContractAddresses[j];
            } else if (counter <= revealedWitnesses.length/2) {
                SLAViolated[SLAContractAddresses[j]] = false;
            }
            counter = 0;
        }              
        for (uint j=0; j < SLAContractAddresses.length; j++) {
            if (SLAViolatedAddresses.length == 0){
                AuctionState = State.Successful;
                emit AuctionStateModified(msg.sender, now, State.Successful);
            } else if (SLAViolatedAddresses.length != 0) {
                AuctionState = State.Violated;
                emit AuctionStateModified(msg.sender, now, State.Violated);
        }
        }
        return true;   
    }

    /**
     * Customer Interface:
     * This is for customer to withdraw the service fee (if the SLA[j] is violated)
     * */ 
    function customerWithdrawServiceFee()
        public
        checkState(State.Violated)
        checkTimeAfter(serviceEnd)
        checkCustomer(msg.sender)
        returns(bool withdrawSuccess)

    {
        for (uint i=0; i < SLAContractAddresses.length; i++) {
            if (SLAViolated[SLAContractAddresses[i]] == true) {
                msg.sender.transfer(SLAContractPool[SLAContractAddresses[i]].serviceFee);
                SLAContractPool[SLAContractAddresses[i]].serviceFee = 0;
            }
        }
        return true;
    }

    /**
     * Provider Interface:
     * This is for provider to withdraw the service fee (if the SLA[j] is not violated)
     * */ 
    function providerWithdrawServiceFee()
        public
        payable
        checkTimeAfter(serviceEnd)
        checkProvider(msg.sender)
        returns(bool withdrawSuccess)
    {
        if (AuctionState == State.Successful || AuctionState == State.Violated){
            for (uint i=0; i < SLAContractAddresses.length; i++) {
                if (winnerBidders[i] == msg.sender && SLAViolated[SLAContractAddresses[i]] == false){
                    msg.sender.transfer(SLAContractPool[SLAContractAddresses[i]].serviceFee);
                    SLAContractPool[SLAContractAddresses[i]].serviceFee = 0;
                    return true;
                }
            }
        }
    }

    /**
     * Customer Interface:
     * This is for customer to reset the auction to Ready state
     * */ 
    function resetSLA()
        public
        checkReset()
        checkTimeAfter(serviceEnd)
        checkCustomer(msg.sender)
    {
        delete winnerBidders;
        delete winnerBids;
        delete loserBidders;
        delete loserBids;
        AuctionState = State.Ready;
        emit AuctionStateModified(msg.sender, now, State.Ready);
    }

    // uint SLAs = 80;
    // uint Witnesses = 100;
    // mapping (address => bytes32[]) public sealedMessageArray;
    // mapping (address => uint[]) public revealedMessageArray;

    // mapping (address => uint256) public submissionDeposit;

    // uint public witnessNum;
    // uint public revealWitnessNum;

    
    // function submitMessages(bytes32[] memory _sealedMessage) 
    //     public
    //     payable
    //     // checkTimeAfter(serviceEnd)
    //     returns(bool reportSuccess)
    // {   
    //     // require (witnessPool[msg.sender].registered = true);       
    //     require (_sealedMessage.length == SLAs);   
    //     require (msg.value >  0 );
    //     sealedMessageArray[msg.sender] = _sealedMessage;
    //     submissionDeposit[msg.sender] = msg.value;
    //     witnessNum++;
    //     if (witnessNum == Witnesses) {
    //         return true;
    //     } 
    // }
    
    
    // function revealMessages (uint[] memory _message, uint _witnessKey)
    //     public
    //     payable
    //     // checkTimeAfter(serviceEnd)
    //     returns(bool revealSuccess)
    // {
    //     uint SLAsNum;
    //     require (_message.length == SLAs && _witnessKey != 0);
    //     for (uint i=0; i < SLAs; i++) {
    //         // check all the monitoring messages (for k SLAs) in the rang 0-10.
    //         require (_message[i] >= 0 && _message[i] <= 100);
    //         if (keccak256(abi.encodePacked(_message[i], _witnessKey)) == sealedMessageArray[msg.sender][i]){
    //             SLAsNum++;
    //         }
    //     }
    //     if (SLAsNum == SLAs) {
    //         revealedMessageArray[msg.sender] = _message;
    //         msg.sender.transfer(submissionDeposit[msg.sender]);
    //         submissionDeposit[msg.sender] = 0;
    //         revealWitnessNum ++;      
    //         if (revealWitnessNum == Witnesses) {
    //             return true;
    //         } 
    //     } 
    // }
    
}


/**
 * The CloudSLA contract manage the service details between provider and customer.
 */
contract CloudSLA {

    address public customer;
    address public provider;
    CloudAuction public MainContract;
    string public serviceDetail;
    uint public serviceFee;

    constructor(CloudAuction _auctionManagement, address _provider, address _customer, string memory _serviceDetail, uint _serviceFee)
        public
    {
        provider = _provider;
        customer = _customer;
        MainContract = _auctionManagement;
        serviceDetail = _serviceDetail;
        serviceFee = _serviceFee;
    }
}