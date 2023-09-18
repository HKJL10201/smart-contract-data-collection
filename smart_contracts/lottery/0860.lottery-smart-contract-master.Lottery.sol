// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import '@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
    
 


contract VRFv2DirectFundingConsumer is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

    // Address of the BUSD Token contract.
    IERC20 public _BUSD;

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

     uint32 callbackGasLimit;// = 120000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations;// = 3;


    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords;// = 3;

    // Address LINK - hardcoded for Binance Testnet
    address linkAddress;// = 	0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;

    // address WRAPPER - hardcoded for Binance Testnet
    address wrapperAddress;// = 0x699d428ee890d55D56d5FC6e26290f3247A762bd;

    uint16 maxBetCount;   //maximum number of bets in a game

    address admin;

    modifier onlyAdmin {
      require(msg.sender == admin,'Only Admin can call This Function');
      _;
   }


    constructor(IERC20 BUSD,address _admin,uint16 _maxBetCount, uint32 _numWords,uint32 _callbackGasLimit,uint16 _requestConfirmations,address _linkAddress,address _wrapperAddress) 
    ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress) {
        _BUSD = BUSD;
        admin=_admin;
        maxBetCount=_maxBetCount;
        numWords=_numWords;
        callbackGasLimit=_callbackGasLimit;
        requestConfirmations=_requestConfirmations;
        linkAddress=_linkAddress;
        wrapperAddress=_wrapperAddress;
    }

    function setAdmin (address _admin) public onlyAdmin{
        admin=_admin;
    }

    function requestRandomWords() external onlyAdmin returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint256[] memory randomWords
        )
    {
        require(s_requests[_requestId].paid > 0, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyAdmin {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }


    //to store user's details
    struct user{
        address _userAddress;
        uint16 _betNumber;
    }
    //user's details w.r.t. requestId
    mapping(uint256 =>user[]) userDetails;

//Particular Bet Details w.r.t. Request Id
    struct betDetails{
        uint16 betCount;
        string status;
        uint latestBetTimestamp;
    }
    mapping(uint256=>betDetails) _betDetails;
    

    function bet(uint256 _amount, uint16 betNumber ,uint256 _requestId) public {
        require(betNumber<=18 && betNumber>=3,'Invalid Bet Number');
        require(_betDetails[_requestId].betCount<maxBetCount,'Limit exceed');
        require(_amount==11*1e18,'Please Enter Sufficient amount');   //11*1e18

        address _to = address(this);
        address _from = msg.sender;
        _BUSD.transferFrom(_from, _to, _amount);

        _betDetails[_requestId].betCount=_betDetails[_requestId].betCount+1;
        _betDetails[_requestId].status="Pending";
        _betDetails[_requestId].latestBetTimestamp=block.timestamp;

        userDetails[_requestId].push(user(msg.sender,betNumber));
        
    }

    function betSettlement(uint16 result, uint256 _requestId) public onlyAdmin {
        for(uint i = 0; i < userDetails[_requestId].length;  i++){
            if(userDetails[_requestId][i]._betNumber == result ){
                _BUSD.transfer(userDetails[_requestId][i]._userAddress,100*1e18);  //100*1e18
                _betDetails[_requestId].status="Settled"; 
            }
        }
    }

    function setVariables(uint32 _numWords,uint32 _callbackGasLimit,uint16 _requestConfirmations,address _linkAddress,address _wrapperAddress)
    public onlyAdmin {
        numWords=_numWords;
        callbackGasLimit=_callbackGasLimit;
        requestConfirmations=_requestConfirmations;
        linkAddress=_linkAddress;
        wrapperAddress=_wrapperAddress;
    }

    function setMaxBetCount(uint16 _maxBetCount) public onlyAdmin{
        maxBetCount=_maxBetCount;
    }

    function getVariablesDetails() public onlyAdmin view 
    returns(uint32 _numWords,uint32 _callbackGasLimit,uint16 _requestConfirmations,address _link_Token_Address,address _wrapperAddress){
        return(numWords,callbackGasLimit,requestConfirmations,linkAddress,wrapperAddress);
    }

//Get Details about Number of Bets and Status of bet
    function betStatus(uint256 _requestId) public onlyAdmin view returns(uint16 TotalNumber_of_bets,string memory Status,uint _latestBetTimestamp){

        return (_betDetails[_requestId].betCount,_betDetails[_requestId].status,_betDetails[_requestId].latestBetTimestamp);
        
    }

//Get User's Bet Number and Address
    function getUserDetails(uint _userNumber, uint256 _requestId) public onlyAdmin view returns(address _Address,uint16 Bet_Number){
        
        return (userDetails[_requestId][_userNumber]._userAddress,userDetails[_requestId][_userNumber]._betNumber);
        
    }

    function withdrawBUSD(uint256 _amount) public onlyAdmin{
        _BUSD.transfer(msg.sender,_amount);
    }
}