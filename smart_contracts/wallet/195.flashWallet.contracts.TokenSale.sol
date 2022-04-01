pragma solidity ^0.5.8;

import "./CalileaToken.sol";
import "./SafeMath.sol";


contract TokenSale {
    using SafeMath for uint256;
    // Address where funds are collected
    address payable _wallet;
    CalileaToken  private _token;
    uint256 public tokensSold;
    uint256 public tokensAvailable = 0;
    uint256 private _guardCounter = 1;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Sell(address _buyer, uint256 _amount);


    event loguint256(uint256 err);
    event logaddress(address err);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (address payable wallet, CalileaToken token, uint256 rate ) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: error, wallet is address(0)");
        require(address(token) != address(0), "Crowdsale: token is the zero address");
        _token = CalileaToken(token);
        _rate = rate;
        _wallet = wallet;
        _token = token;

    }

    function endSale () public {

            require (msg.sender == _wallet);
            require (_token.transfer(_wallet, _token.balanceOf(address(this))));
            selfdestruct(_wallet);
    }

    function initializeIco(uint256 _tokensAvailable) public  nonReentrant  {
        require(msg.sender == _wallet);
        tokensAvailable = _tokensAvailable;
    }
    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    * Note that other contracts will transfer funds with a base gas stipend
    * of 2300, which is not enough to call buyTokens. Consider calling
    * buyTokens directly when purchasing tokens from a contract.
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (CalileaToken) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount, tokensAvailable);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        emit loguint256(tokens);
        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);

        // add tokens to tokens sold counter
        tokensSold = _updatetokensSold(tokens);

        // substract tokens to tokens availables
        tokensAvailable = _updatetokensAvailables(tokens);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();

        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
   function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 _tokensAvailable) internal pure {
        require(_tokensAvailable > 0, "Crowsale: not tokens availables");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount.mul(10**18));
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.div(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev register tokens sum has been sold.
     */
    function _updatetokensSold(uint256 tokens) internal view  returns (uint256)  {
       return  tokensSold.add(tokens);
    }
    /**
     * @dev update  tokens availables, after they has been sold.
     */
    function _updatetokensAvailables(uint256 tokens) internal view  returns (uint256)  {
       return  tokensAvailable.sub(tokens);
    }
}