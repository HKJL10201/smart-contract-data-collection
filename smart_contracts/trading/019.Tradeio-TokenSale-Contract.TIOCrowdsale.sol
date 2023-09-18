pragma solidity ^0.4.15;

/**
 * TradeToken Crowdsale Contract
 *
 * This is the crowdsale contract for the TradeToken. It utilizes Majoolr's
 * CrowdsaleLib library to reduce custom source code surface area and increase
 * overall security.Majoolr provides smart contract services and security reviews
 * for contract deployments in addition to working on open source projects in the
 * Ethereum community.
 * For further information: trade.io, majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import "./DirectCrowdsaleLib.sol";
import "./CrowdsaleToken.sol";

contract TIOCrowdsale {
  using DirectCrowdsaleLib for DirectCrowdsaleLib.DirectCrowdsaleStorage;

  DirectCrowdsaleLib.DirectCrowdsaleStorage sale;
  bool public greenshoeActive;

  function TIOCrowdsale(
                address owner,
                uint256[] saleData,           // [1511823660, 200, 0, 1512428340, 240, 0, 1513033140, 300, 0]
                uint256 fallbackExchangeRate, // 30000
                uint256 capAmountInCents,     // 99000000000
                uint256 endTime,              // 1511974800
                uint8 percentBurn,            // 100
                CrowdsaleToken token)         // 0x80bc5512561c7f85a3a9508c7df7901b370fa1df
  {
  	sale.init(owner, saleData, fallbackExchangeRate, capAmountInCents, endTime, percentBurn, token);
  }

  // fallback function can be used to buy tokens
  function () payable {
    sendPurchase();
  }

  function sendPurchase() payable returns (bool) {
    uint256 _tokensSold = getTokensSold();
    if(_tokensSold > 270000000000000000000000000 && (!greenshoeActive)){
      bool success = activateGreenshoe();
      assert(success);
    }
  	return sale.receivePurchase(msg.value);
  }

  function activateGreenshoe() private returns (bool) {
    uint256 _currentPrice = sale.base.saleData[sale.base.milestoneTimes[sale.base.currentMilestone]][0];
    while(sale.base.milestoneTimes.length > sale.base.currentMilestone + 1)
    {
      sale.base.currentMilestone += 1;
      sale.base.saleData[sale.base.milestoneTimes[sale.base.currentMilestone]][0] = _currentPrice;
    }
    greenshoeActive = true;
    return true;
  }

  function withdrawTokens() returns (bool) {
  	return sale.withdrawTokens();
  }

  function withdrawLeftoverWei() returns (bool) {
    return sale.withdrawLeftoverWei();
  }

  function withdrawOwnerEth() returns (bool) {
    return sale.withdrawOwnerEth();
  }

  function crowdsaleActive() constant returns (bool) {
    return sale.crowdsaleActive();
  }

  function crowdsaleEnded() constant returns (bool) {
    return sale.crowdsaleEnded();
  }

  function setTokenExchangeRate(uint256 _exchangeRate) returns (bool) {
    return sale.setTokenExchangeRate(_exchangeRate);
  }

  function setTokens() returns (bool) {
    return sale.setTokens();
  }

  function getOwner() constant returns (address) {
    return sale.base.owner;
  }

  function getTokensPerEth() constant returns (uint256) {
    return sale.base.tokensPerEth;
  }

  function getExchangeRate() constant returns (uint256) {
    return sale.base.exchangeRate;
  }

  function getCapAmount() constant returns (uint256) {
    if(!greenshoeActive) {
      return sale.base.capAmount - 550000000000000000000000;
    } else {
      return sale.base.capAmount;
    }
  }

  function getStartTime() constant returns (uint256) {
    return sale.base.startTime;
  }

  function getEndTime() constant returns (uint256) {
    return sale.base.endTime;
  }

  function getEthRaised() constant returns (uint256) {
    return sale.base.ownerBalance;
  }

  function getContribution(address _buyer) constant returns (uint256) {
  	return sale.base.hasContributed[_buyer];
  }

  function getTokenPurchase(address _buyer) constant returns (uint256) {
  	return sale.base.withdrawTokensMap[_buyer];
  }

  function getLeftoverWei(address _buyer) constant returns (uint256) {
    return sale.base.leftoverWei[_buyer];
  }

  function getSaleData(uint256 timestamp) constant returns (uint256[3]) {
    return sale.getSaleData(timestamp);
  }

  function getTokensSold() constant returns (uint256) {
    return sale.base.startingTokenBalance - sale.base.withdrawTokensMap[sale.base.owner];
  }

  function getPercentBurn() constant returns (uint256) {
    return sale.base.percentBurn;
  }
}
