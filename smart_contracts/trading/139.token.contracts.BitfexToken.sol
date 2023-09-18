pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract BitfexToken is MintableToken {
    string public name = "BitFex Token";
    string public symbol = "BITFEX";
    uint8 public decimals = 2;

    uint256 public PRE_ICO_TOKENS_AMOUNT = 2000000;
    uint256 public ICO_TOKENS_AMOUNT = 3000000;
    uint256 public OWNERS_TOKENS_AMOUNT = 4000000;
    uint256 public BOUNTY_TOKENS_AMOUNT = 1000000;
    uint256 public TOTAL_SUPPLY = PRE_ICO_TOKENS_AMOUNT + ICO_TOKENS_AMOUNT + OWNERS_TOKENS_AMOUNT + BOUNTY_TOKENS_AMOUNT;

    bool public mintingFinished = false;

    function preallocate(address _preICO, address _ICO, address _ownersWallet, address _bountyWallet) onlyOwner canMint public returns (bool) {
      assert(TOTAL_SUPPLY == 10000000); // check that total tokens amount is 100 000.00 tokens
      mint(_preICO, PRE_ICO_TOKENS_AMOUNT);
      mint(_ICO, ICO_TOKENS_AMOUNT);
      mint(_ownersWallet, OWNERS_TOKENS_AMOUNT);
      mint(_bountyWallet, BOUNTY_TOKENS_AMOUNT);

      mintingFinished = true;
      emit MintFinished();

      return true;
    }
}
