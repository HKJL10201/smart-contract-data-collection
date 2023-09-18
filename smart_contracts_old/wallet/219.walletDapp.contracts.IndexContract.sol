pragma solidity ^0.4.21;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import {Token} from './Token.sol';
import {Exchange} from './Exchange.sol';
import {ReentrancyGuard} from './ReentrancyGuard.sol';

contract IndexContract is Ownable, ReentrancyGuard {
		using SafeMath for uint256;
		uint256 constant MAX_UINT = 2**256 - 1;

		event allowanceSet(address tokenAddress);

		modifier requireNonZero(uint256 value) {
        require(value > 0);
        _;
    }

		// TokenInfo is the address of the tokens and the %age weight
		struct TokenInfo {
        address addr;
        uint256 weight;
				uint256 curr_quantity;
    }

		TokenInfo[] public _tokens;
		uint256 public _rebalanceInBlocks;
		uint256 public _lastRebalanced;
		address _proxyAddress; // Address of token transfer proxy: https://0xproject.com/wiki#Deployed-Addresses
		address _WETHAddress;
		Exchange _exchange;
    address _diyindex;
    
		mapping (address => uint256) public balances;

		constructor(
			address[] addresses, 
			uint256[] weights, 
			uint256 rebalanceInBlocks,
			address proxyAddress,
			address exchangeAddress,
			address WETHAddress,
      address diyindex
		) public {
			  require(addresses.length > 0);
        require(addresses.length == weights.length);
				require(rebalanceInBlocks > 0);

				_rebalanceInBlocks = rebalanceInBlocks;
				_proxyAddress = proxyAddress;
				_exchange = Exchange(exchangeAddress);
				_WETHAddress = WETHAddress;
        _diyindex = diyindex;
				_lastRebalanced = 0;
				
        for (uint256 i = 0; i < addresses.length; i++) {
            _tokens.push(TokenInfo({
                addr: addresses[i],
                weight: weights[i],
								curr_quantity: 0
            }));
        }
		}

		function get_token(address a) internal nonReentrant returns (Token) {
				uint256 i;
				bool exists;
				(i, exists) = get_index(_WETHAddress);	
				require(exists);
				Token token = Token(_WETHAddress);
				return token;
		}

		function update_token_quantity(address a, uint256 amount, bool append, bool add) internal nonReentrant returns (bool) {
				uint256 i;
				bool exists;
				(i, exists) = get_index(a);	
				require(exists);
				if (append) {
					if (add) {	
						_tokens[i].curr_quantity = _tokens[i].curr_quantity.add(amount);
					} else {
						_tokens[i].curr_quantity = _tokens[i].curr_quantity.sub(amount);
					}
				} else {
					_tokens[i].curr_quantity = amount;
				}
				return true;
		}

		function deposit_weth(uint256 amount) external onlyOwner requireNonZero(amount) returns (bool success) {
        Token token = get_token(_WETHAddress);
				require(token.transferFrom(msg.sender, this, amount));
				return update_token_quantity(_WETHAddress, amount, true, true);
		}
		
		function withdraw() external onlyOwner nonReentrant returns (bool success) {
				for (uint256 i = 0; i < _tokens.length; i++) {
            TokenInfo memory withdraw_token = _tokens[i];
            Token token = Token(withdraw_token.addr);
						uint256 balance = token.balanceOf(address(this));
            // uint256 balance = withdraw_token.curr_quantity;
						if (balance > 0) {
							require(update_token_quantity(withdraw_token.addr, 0, false, true));
							require(token.transfer(owner, balance));
						}
        }	
        return true;
		}

		function get_last_rebalanced() external view returns (uint256) {
			return _lastRebalanced;
		}

		function rebalance_in_blocks() external view returns (uint256) {
			return _rebalanceInBlocks;
		}

		/// @return addresses
    function token_addresses() external view returns (address[]){
        address[] memory addresses = new address[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            addresses[i] = _tokens[i].addr;
        }
        return addresses;
    }

		/// @return weight that we'd like to achieve
    function token_weight() external view returns (uint256[]){
        uint256[] memory weight = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            weight[i] = _tokens[i].weight;
        }
        return weight;
    }

		/// @return weight that we'd like to achieve
    function token_quantities() external view returns (uint256[]){
        uint256[] memory quantities = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            quantities[i] = _tokens[i].curr_quantity;
        }
        return quantities;
    }

		function get_index(address token) internal view returns (uint256, bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i].addr == token) {
                return (i, true);
            }
        }
        return (0, false);
    }

		//
		// Makes token tradeable by setting an allowance for etherDelta and 0x proxy contract.
		// Also sets an allowance for the owner of the contracts therefore allowing to withdraw tokens.
		//
    function set_allowances(address tokenAddress) external onlyOwner {
        Token token = Token(tokenAddress);
        token.approve(_proxyAddress, MAX_UINT);
        token.approve(owner, MAX_UINT);
				token.approve(_diyindex, MAX_UINT);
				// The smart contract should be allowed to trade this
				// token.approve(address(this), MAX_UINT);
				emit allowanceSet(tokenAddress);
    }

		function maker_amt(uint256 fillTakerTokenAmount, uint256 makerTokenAmount, uint256 takerTokenAmount) external pure returns (uint256) {
				uint256 multiplier = 1000000000000000000;	
				// uint256 maker_amount = fillTakerTokenAmount.mul(multiplier).div(takerTokenAmount).mul(makerTokenAmount).div(multiplier);
				uint256 v1 = fillTakerTokenAmount.mul(multiplier);
				uint256 v2 = v1.div(takerTokenAmount);
				uint256 v3 = v2.mul(makerTokenAmount);
				return v3.div(multiplier);
		}

		// make_exchange_trade: Allows the contract to fill an exchange order
		// This function is called either by DIY or by the owner of the contract
		// The accuracy of the order is enforced by DIY or the owner.
		function make_exchange_trade(
        address[5] addresses, uint[7] values,
        uint8 v, bytes32 r, bytes32 s
    ) public requireNonZero(values[6]) returns (bool success) {
				uint256 block_height = block.number;
        // make exchange trade can only be called by us
        require(msg.sender == _diyindex || msg.sender == owner);
				require(block_height > _lastRebalanced + _rebalanceInBlocks);
        address[5] memory orderAddresses = [
            addresses[0], // maker
            addresses[1], // taker
            addresses[2], // makerToken
            addresses[3], // takerToken
            addresses[4] // feeRecepient
        ];
        uint[6] memory orderValues = [
            values[0], // makerTokenAmount
            values[1], // takerTokenAmount
            values[2], // makerFee
            values[3], // takerFee
            values[4], // expirationTimestampInSec
            values[5]  // salt
        ];
        uint fillTakerTokenAmount = values[6]; // fillTakerTokenAmount
        // Execute Exchange trade. It either succeeds in full or fails and reverts all the changes.
        _exchange.fillOrKillOrder(orderAddresses, orderValues, fillTakerTokenAmount, v, r, s);
				_lastRebalanced = block_height;
				// *add* takerTokenAmount to takerToken address
				require(update_token_quantity(addresses[3], fillTakerTokenAmount, true, false));
				uint256 maker_qty = this.maker_amt(fillTakerTokenAmount, values[0], values[1]);
				// *subtract* the amount from makerToken
				require(update_token_quantity(addresses[2], maker_qty, true, true));
				return true;
    }
}
