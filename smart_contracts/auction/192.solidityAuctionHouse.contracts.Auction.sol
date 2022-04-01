pragma solidity ^0.4.18;
import "./Timer.sol";

contract Auction {

    address internal judgeAddress;
    address internal timerAddress;
    address internal sellerAddress;
    address internal winnerAddress;

    // constructor
    function Auction(address _sellerAddress,
                     address _judgeAddress,
                     address _timerAddress) public {

        judgeAddress = _judgeAddress;
        timerAddress = _timerAddress;
        sellerAddress = _sellerAddress;
        if (sellerAddress == 0)
          sellerAddress = msg.sender;
    }

    // This is provided for testing
    // You should use this instead of block.number directly
    // You should not modify this function.
    function time() public view returns (uint) {
        if (timerAddress != 0)
          return Timer(timerAddress).getTime();

        return block.number;
    }

    // If no judge is specified, anybody can call this.
    // If a judge is specified, then only the judge or winning bidder may call.
    function finalize() public {
        if (judgeAddress != 0)
          require(msg.sender == judgeAddress || msg.sender == getWinner());
        require(getWinner() != 0);

        return sellerAddress.transfer(this.balance);
    }

    // This can ONLY be called by seller or the judge (if a judge exists).
    // Money should only be refunded to the winner.
    function refund() public {
      require(msg.sender == judgeAddress || msg.sender == sellerAddress);
      require(getWinner() != 0);

      return getWinner().transfer(this.balance);
    }

    function getWinner() public returns (address winner){
        return winnerAddress;
    }

}
