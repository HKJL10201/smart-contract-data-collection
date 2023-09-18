//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**@title No loss Lottery Dapp
  *@author ljrr3045
  *@notice This contract seeks to implement a system where users can participate in a 
  lottery where they do not have losses. They can always withdraw their initial investment, 
  and if they are the winners of the lottery they can charge interest.
*/

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "./Interfaces/IRamdomNumber.sol";
import "./Interfaces/IVRFCoordinatorMock.sol";
import "./Interfaces/IProvider.sol";
import "./Interfaces/ISwap.sol";
import "./Interfaces/IcErc20.sol";

contract LotteryV1{

    bool internal init;
    address internal admin;
    address internal dai;
    address internal usdc;
    address internal usdt;
    address internal weth;
    address internal pool3;
    uint public tikectPriceInToken;
    uint public tikectPriceInEth;
    uint internal time;
    uint public lotteryRound;
    IProvider internal provider;
    ISwap internal exchange;
    IRamdomNumber internal ramdomNumber;
    IcErc20 internal cToken;
    ISwapRouter internal swapRouter;
    IPeripheryPayments internal peripheryPayments;
    IVRFCoordinator internal vrfCoordinator;
    ///@dev These are the global variables used for contract management.

//Enums

    ///@dev Enum used to identify the tokens used.
    enum Token {DAI, USDC, USDT, WETH}

//Mappins

    /**@dev Each of these mappings is responsible for storing the different data recorded by 
      users throughout the different rounds.
    */
    mapping(uint => mapping(address => uint)) public userTicketBalanceWithToken;
    mapping(uint => mapping(address => uint)) public userTicketBalanceWithEth;
    mapping(uint => mapping(uint => address)) public ticketOwner;
    mapping(uint => uint) public ticketCount;
    mapping(uint => uint) public lotteryWinner;
    mapping(uint => uint) public amountPool;
    mapping(uint => bool) public setCompone;
    mapping(uint => uint) public winnerAmount;


//Events

    event buyTicket(address buyer, uint round, uint ticketNumber);
    event withdrawalOfMoney(address ownerTickets, uint round, bytes32 message);
    event winnerClaimsPrize(address winner, uint round, bytes32 message);

//Modifiers

    /**@notice This modifier is in charge of modifying all the corresponding data, once 7 days have passed 
      since the beginning (it is found in all the functions so that it can update the data automatically).
      *@dev It is in charge of obtaining the winning ticket of the round, withdrawing the funds from the compound, 
      updating the lottery round, etc.
    */
    modifier upDateData() {

        if(block.timestamp > (time + 7 days)){

            lotteryWinner[lotteryRound] = _getRamdomNumber(ticketCount[lotteryRound]);
            winnerAmount[lotteryRound] = _balanceOfUnderlying(lotteryRound);
            time = block.timestamp;
            lotteryRound++;
            ticketCount[lotteryRound + 1] = 1;
        }
        _;
    }

    /**@notice This modifier is in charge of modifying all the corresponding data, once 2 days have passed 
      since the beginning (it is found in all the functions so that it can update the data automatically).
      *@dev It is in charge of investing the funds, collected during the previous two days, in compound.
    */
    modifier investCompone() {
        if(block.timestamp > (time + 2 days)){
            if(setCompone[lotteryRound] == false){
                _componeMint(amountPool[lotteryRound]);
                setCompone[lotteryRound] = true;
            }
        }
        _;
    }

    ///@dev This modifier check if the person calling the function is the admin of the contract.
    modifier onlyAdmin() {
        require(admin == msg.sender, "Caller is not the Admin");
        _;
    }

//Public Functions

    /**@notice Function that is the constructor of the contract and initialize all variables.
      *@dev Can only be called once.
    */
    function initContract(address _ramdomNumber, address _vrfCoordinator) public{
        require(init == false, "Contract are init");
        admin = msg.sender;

        cToken = IcErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        ramdomNumber = IRamdomNumber(_ramdomNumber);
        vrfCoordinator = IVRFCoordinator(_vrfCoordinator);
        provider = IProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);
        exchange = ISwap(provider.get_address(2));
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        peripheryPayments = IPeripheryPayments(0xE592427A0AEce92De3Edee1F18E0157C05861564);

        pool3 = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

        dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        tikectPriceInToken = 10;
        tikectPriceInEth = 3000000000000000;

        lotteryRound = 1;
        ticketCount[lotteryRound] = 0;
        ticketCount[lotteryRound + 1] = 0;
        time = block.timestamp;
        init = true;
    }

    /**@notice This feature allows the user to buy lottery tickets only with stable coins (DAI, USDC, USDT).
      *@dev Depending on the elapsed time, your tickets will be assigned to the current or next round. Also all the 
      money received will be swap to DAI.
      *@dev The money obtained from the swap (with Curve Finance) will be stored in a mapping so that it can later be returned to the user 
      when the lottery ends.
    */
    function buyTicketWithToken(uint _amount, Token _token) public investCompone upDateData{
        require( _token != Token.WETH, "Eth is not allowed here");

        uint _amountPool;
        uint amountTikects;

        if(_token == Token.USDT){

            require(_amount > (tikectPriceInToken * (10 ** 6)), "Not enough payment");
            require((_amount % (tikectPriceInToken * (10 ** 6))) == 0, "The number of tickets is not whole");
            amountTikects = _amount / (tikectPriceInToken * (10 ** 6));
            _transferToken(usdt,_amount);
            _amountPool = _swapper(pool3, usdt, dai, _amount);

        } else if(_token == Token.USDC){

            require(_amount > (tikectPriceInToken * (10 ** 6)), "Not enough payment");
            require((_amount % (tikectPriceInToken * (10 ** 6))) == 0, "The number of tickets is not whole");
            amountTikects = _amount / (tikectPriceInToken * (10 ** 6));
            _transferToken(usdc,_amount);
            _amountPool = _swapper(pool3, usdc, dai, _amount);

        }else{

            require(_amount > (tikectPriceInToken * (10 ** 18)), "Not enough payment");
            require((_amount % (tikectPriceInToken * (10 ** 18))) == 0, "The number of tickets is not whole");
            amountTikects = _amount / (tikectPriceInToken * (10 ** 18));
            _transferToken(dai,_amount);
            _amountPool = _amount;
        }

        if(block.timestamp <= (time + 2 days)){
            userTicketBalanceWithToken[lotteryRound][msg.sender] += _amountPool;
            amountPool[lotteryRound] += _amountPool;
            for(uint i=0; i<amountTikects; i++){
                _ticketAsing(lotteryRound);
            } 
        }else{
            userTicketBalanceWithToken[lotteryRound + 1][msg.sender] += _amountPool; 
            amountPool[lotteryRound + 1] += _amountPool;
            for(uint i=0; i<amountTikects; i++){
                _ticketAsing(lotteryRound + 1);
            }
        }
    }

    /**@notice This feature allows the user to buy lottery tickets only with ETH.
      *@dev Depending on the elapsed time, your tickets will be assigned to the current or next round. Also all the 
      money received will be swap to DAI.
      *@dev The money obtained from the swap (with UniSwap) will be stored in a mapping so that it can later be returned to the user 
      when the lottery ends.
    */
    function buyTicketWithEth() public payable investCompone upDateData{
        require(msg.value > tikectPriceInEth, "Not enough payment");
        require((msg.value % tikectPriceInEth) == 0, "The number of tickets is not whole");

        uint _amountPool;
        uint _amountPoolBefore;
        uint amountTikects;

        amountTikects = msg.value / tikectPriceInEth;
        _amountPoolBefore = IERC20Upgradeable(dai).balanceOf(address(this));
        _swapEthForToken(weth, dai, msg.value);
        _amountPool = IERC20Upgradeable(dai).balanceOf(address(this)) - _amountPoolBefore;
 
        if(block.timestamp <= (time + 2 days)){
            userTicketBalanceWithEth[lotteryRound][msg.sender] += _amountPool;
            amountPool[lotteryRound] += _amountPool;
            for(uint i=0; i<amountTikects; i++){
                _ticketAsing(lotteryRound);
            } 
        }else{
            userTicketBalanceWithEth[lotteryRound + 1][msg.sender] += _amountPool; 
            amountPool[lotteryRound + 1] += _amountPool;
            for(uint i=0; i<amountTikects; i++){
                _ticketAsing(lotteryRound + 1);
            }
        }
    }

    /**@notice Function that allows the winner of the lottery to claim his prize obtained from the investment in compound.
      *@dev The money will be deposited in DAI and you can only withdraw the money if the lottery round is over.
    */
    function iWinWantToWithdraw(uint _round) public investCompone upDateData{
        require(_round > 0 && _round < lotteryRound, "Can't withdraw for this round yet");
        require(ticketOwner[_round][lotteryWinner[_round]] == msg.sender, "You are not the winner");
        require(winnerAmount[_round] > 0, "You already claimed your prize");

        uint payAdmin = (winnerAmount[_round] * 5) / 100;
        uint payWinner = winnerAmount[_round] - payAdmin;

        _transferTokenOut(dai, payAdmin, admin);
        _transferTokenOut(dai, payWinner, msg.sender);
        winnerAmount[_round] = 0;

        emit winnerClaimsPrize(msg.sender, _round, "Winner has claimed his prize");
    }

    /**@notice Function that allows the user to withdraw all their money invested in tickets in a round.
      (only if I buy with tokens).
      *@dev The user can withdraw all his money in any stablecoin (all the money will be exchanged based on 
      the amount of DAI he entered). Can only withdraw your money if the round is over.
    */
    function getMyMoneyBackInToken(Token _token, uint _round) public investCompone upDateData{
        require( _token != Token.WETH, "Eth is not allowed here");
        require(_round > 0 && _round < lotteryRound, "Can't withdraw for this round yet");
        require(userTicketBalanceWithToken[_round][msg.sender] > 0, "Not have available balance in this round");

        uint _exchange;
        uint _amount;

        if(_token == Token.USDT){
           _amount = userTicketBalanceWithToken[_round][msg.sender];
           IERC20Upgradeable(dai).approve(address(exchange), _amount);
           _exchange = _swapper(pool3, dai, usdt, _amount);
           _transferTokenOut(usdt, _exchange, msg.sender);
           userTicketBalanceWithToken[_round][msg.sender] = 0;

        }else if(_token == Token.USDC){
            _amount = userTicketBalanceWithToken[_round][msg.sender];
            IERC20Upgradeable(dai).approve(address(exchange), _amount);
            _exchange = _swapper(pool3, dai, usdc, _amount);
            _transferTokenOut(usdc, _exchange, msg.sender);
            userTicketBalanceWithToken[_round][msg.sender] = 0;

        }else{
            _amount = userTicketBalanceWithToken[_round][msg.sender];
            _transferTokenOut(dai, _amount, msg.sender);
            userTicketBalanceWithToken[_round][msg.sender] = 0;
        }

        emit withdrawalOfMoney(msg.sender, _round, "Have withdrawn your money");
    }

    /**@notice Function that allows the user to withdraw all their money invested in tickets in a round.
      (only if I buy with ETH).
      *@dev The user can withdraw all his invested money and will get the equivalent WETH in exchange 
      (all the money will be exchanged based on the amount of DAI that he entered). Can only withdraw your 
      money if the round is over.
    */
    function getMyMoneyBackInEth(uint _round) public investCompone upDateData{
        require(_round > 0 && _round < lotteryRound, "Can't withdraw for this round yet");
        require(userTicketBalanceWithEth[_round][msg.sender] > 0, "Not have available balance in this round");

        uint _amount;

        _amount = userTicketBalanceWithEth[_round][msg.sender];
        IERC20Upgradeable(dai).approve(address(swapRouter), _amount);
        _swapTokenForEth(dai, weth, _amount);
        userTicketBalanceWithEth[_round][msg.sender] = 0;

        emit withdrawalOfMoney(msg.sender, _round, "Have withdrawn your money");
    }

    /**@dev Backup function in the event that users do not call the classic functions and therefore the data is not 
      updated in relation to time. This function can be called by the Admin and thus update the data manually, if the 
      times are the corresponding ones (Only Admin can execute this action).
    */
    function setUpDateDate() public onlyAdmin investCompone upDateData{}

    ///@dev Function that allows to modify the Admin of the contract (Only Admin can execute this action).
    function transferAdmin(address  newAdmin) public virtual onlyAdmin {
        require( newAdmin != address(0), "Ownable: new owner is the zero address");
        admin = newAdmin;
    }

//Internal Functions

    ///@dev Function that assigns ownership of a specific ticket (from a given round) to the caller of the function.
    function _ticketAsing(uint _round) internal {
        ticketOwner[_round][ticketCount[_round] + 1] = msg.sender;
        ticketCount[_round] += 1;

        emit buyTicket(msg.sender, _round, ticketCount[_round]);
    }

    ///@dev Function to exchange stablecoins using Curve Finances.
    function _swapper(address _pool, address _tokenFrom, address _tokenTo, uint _amount) internal returns(uint){

        uint _exchage = exchange.exchange(_pool, _tokenFrom, _tokenTo, _amount, 1, address(this));
        return _exchage;
    }

    ///@dev Function to exchange ETH for stablecoins using UniSwap.
    function _swapEthForToken(address _tokenIn, address _tokenOut, uint amountIn) internal {

        uint24 poolFee = 3000;

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 10,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            }
        );

        swapRouter.exactInputSingle{ value: amountIn }(params);
        peripheryPayments.refundETH();
    }

    ///@dev Function to exchange stablecoins for WETH using UniSwap.
    function _swapTokenForEth(address _tokenIn, address _tokenOut, uint _amountIn) internal {

        uint24 poolFee = 3000;

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp + 10,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            }
        );

        swapRouter.exactInputSingle(params);
    }

    /**@dev Function to transfer tokens from a user to a contract. And if it is not DAI, approve them for Curve 
      Finances to change them to DAI
    */
    function _transferToken(address _token, uint _amount) internal {

        IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), _amount);

        if(_token != dai){
            IERC20Upgradeable(_token).approve(address(exchange), _amount);
        }
    }

    ///@dev Function to transfer tokens from the contract to a user.
    function _transferTokenOut(address _token, uint _amount, address _to) internal {
        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    ///@dev Function to start an investment with Compound Finances.
    function _componeMint(uint _amount) internal {
        IERC20Upgradeable(dai).approve(address(cToken), _amount);
        require(cToken.mint(_amount) == 0, "mint failed");
    }

    ///@dev Function to check the balance invested in Compound Finances.
    function _getCTokenBalance() internal view returns (uint) {
        return cToken.balanceOf(address(this));
    }

    ///@dev Function to withdraw the balance invested and obtained in Compound Finances.
    function _componeRedeem(uint _amount) internal {
        require(cToken.redeem(_amount) == 0, "redeem failed");
    }

    ///@dev Function to verify the profit generated from the investment in Compound Finances.
    function _balanceOfUnderlying(uint _round) internal returns (uint) {
        uint balanceBefore;
        uint balanceAfter;

        balanceBefore = IERC20Upgradeable(dai).balanceOf(address(this));
        _componeRedeem(_getCTokenBalance());
        balanceAfter = IERC20Upgradeable(dai).balanceOf(address(this));

        return balanceAfter - (balanceBefore + amountPool[_round]);
    }

    /**@dev Function that allows obtaining a random number using the ChainLink oracle (We can specify 
      up to what number we want our random number, starting from 1).
    */
    function _getRamdomNumber(uint _until) internal returns(uint){
        ramdomNumber.setUntil(_until);
        ramdomNumber.getRandomNumber();
        vrfCoordinator.callBackWithRandomness(ramdomNumber.lastRequestId(),777,address(ramdomNumber));
        return ramdomNumber.randomResult();
    }
}