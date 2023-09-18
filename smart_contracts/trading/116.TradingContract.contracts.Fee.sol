pragma solidity >=0.6.0 <0.7.0;

import "./openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./openzeppelin-contracts/contracts/utils/EnumerableSet.sol";
import "./openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Fee {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    
    struct Deposit {
        uint256 depositID;
        uint256 amount;
        uint256 untilTime;
        uint256 durationTime;
        bool directToAccount;
        bool exists;
    }

    struct FeeStruct {
        address feeIdent;
        mapping(address => Deposit[]) feeMap;
        mapping(address => uint256) yields;
        EnumerableSet.AddressSet feeSet;
        uint256 totalBalance;
        uint256 feeValue;
    }
    
    // here address - token as identificator
    mapping(address => FeeStruct) private feeList;
    
    event AccrualFee(address indexed addr, uint256 amount);
    
    event DepositCreated(uint256 depositID, address indexed addr, uint256 amount);
    event DepositWithdrawn(uint256 depositID, address indexed addr, uint256 amount);
    

    /**
     * @param token1 address of token1. used as identificator in mapping
     * @param token2 address of token2(or address(0) for ETH). used as identificator in mapping
     * @param fee1 // 1 means 0.000001% mul 1e6
     * @param fee2 // 1 means 0.000001% mul 1e6
     */
    constructor(address token1, address token2, uint256 fee1, uint256 fee2) public {
        
            feeList[token1].feeIdent = token1;
            feeList[token1].totalBalance = 0;
            feeList[token1].feeValue = fee1;    
        
            feeList[token2].feeIdent = token1;
            feeList[token2].totalBalance = 0;
            feeList[token2].feeValue = fee2; 
            
    }
    
    /**
     * set funds as deposit 
     * @param ident identificator
     * @param amount amount of tokens
     * @param durationTime duration in seconds
     * @param directToAccount if true then funds from deposit will send to account directly else accumulated in contract
     */
    function setFunds(address ident, uint256 amount, uint256 durationTime, bool directToAccount)  internal {
        uint256 depositID = generateDepositID();
        feeList[ident].feeMap[msg.sender].push(
            Deposit({
                depositID: depositID,
                amount: amount,
                untilTime: now.add(uint256(durationTime)),
                durationTime: uint256(durationTime),
                directToAccount: directToAccount,
                exists: true
            })
        );
        
            
        feeList[ident].feeSet.add(msg.sender);
        feeList[ident].totalBalance = feeList[ident].totalBalance.add(amount);

        emit DepositCreated(depositID, msg.sender, amount);
        
    }
    
    /**
     * view status of deposits 
     * @param ident identificator
     */
    function viewFunds(
        address ident
    ) 
        internal 
        view 
        returns
    (
        uint256[] memory depositIDs, 
        uint256[] memory amounts, 
        uint256[] memory untilTime, 
        bool[] memory directToAccounts
    ) {
        // returns(Deposit[] memory)
        for(uint256 i = 0; i < feeList[ident].feeMap[msg.sender].length; i++) {
            depositIDs[i] = feeList[ident].feeMap[msg.sender][i].depositID;
            amounts[i] = feeList[ident].feeMap[msg.sender][i].amount;
            untilTime[i] = feeList[ident].feeMap[msg.sender][i].untilTime;
            directToAccounts[i] = feeList[ident].feeMap[msg.sender][i].directToAccount;
        }
    }
    
    /**
     * withdraw current deposit
     * @param depositID identificator
     * @param withYield with yield or not
     * @param tokenIdent erc20 token address or address(0x0) mean ether
     * @param overallBalance overall balance of contract in deposited token
     */
    function withdrawFunds(uint256 depositID, bool withYield, address tokenIdent, uint256 overallBalance)  internal returns (uint256 amountLeft) {
        
        
        // find deposit by ID
        bool isExists = false;
        uint256 index = 0;
        for(uint256 i = 0; i < feeList[tokenIdent].feeMap[msg.sender].length; i++) {
            if (feeList[tokenIdent].feeMap[msg.sender][i].depositID == depositID) {
                isExists = true;
                index = i;
                break;
            }
        }
        
        if (isExists) {
            require(
                feeList[tokenIdent].feeMap[msg.sender][index].untilTime < now, 
                string(abi.encodePacked('Withdraw will be available after unixtimestamp #', uint2str(feeList[tokenIdent].feeMap[msg.sender][index].untilTime)))
            );
            
            emit DepositWithdrawn(depositID, msg.sender, feeList[tokenIdent].feeMap[msg.sender][index].amount);
            
            // body   feeList[ident].feeMap[msg.sender][index].amount
            uint256 amount2send;
            if (feeList[tokenIdent].feeMap[msg.sender][index].amount > overallBalance) {
                amount2send = overallBalance;
                amountLeft = (feeList[tokenIdent].feeMap[msg.sender][index].amount).sub(overallBalance);
            } else {
                amount2send = feeList[tokenIdent].feeMap[msg.sender][index].amount;
                amountLeft = 0;
            }
            
            uint256 countFee = feeList[tokenIdent].feeSet.length();
            bool feeProceed = false;
            // fee 
            uint256 feeAmount = (
                    amount2send
                ).
                mul(
                    feeList[tokenIdent].feeValue
                ).
                div(1e6);
            uint256 initialSenderDeposit = feeList[tokenIdent].feeMap[msg.sender][index].amount;
            feeProceed = accuralFee(tokenIdent, depositID, feeAmount, initialSenderDeposit);
            
            if (feeProceed == true) {
                amount2send = amount2send.sub(feeAmount);
            } else {
                // if no any deposits add feeCount  back to Sender    
            }
            
            
            removeDeposit(tokenIdent, msg.sender, index);
            sendFunds(tokenIdent, msg.sender, amount2send);
            
            // yield amount
            uint256 yieldAmount = feeList[tokenIdent].yields[msg.sender];
    
            if (withYield == true && yieldAmount > 0) {
                
                feeList[tokenIdent].yields[msg.sender] = 0;
                sendFunds(tokenIdent, msg.sender, yieldAmount);
            }
            
        } else {
            
        }
        
        
    }
    
    function removeDeposit(address tokenIdent, address addr, uint256 index) private {
        
        uint amount = feeList[tokenIdent].feeMap[addr][index].amount;
        feeList[tokenIdent].totalBalance = feeList[tokenIdent].totalBalance.sub(amount);
        
        for (uint j = index; j<feeList[tokenIdent].feeMap[addr].length-1; j++){
            feeList[tokenIdent].feeMap[addr][j] = feeList[tokenIdent].feeMap[addr][j+1];
        }
            
        feeList[tokenIdent].feeMap[addr].pop();
            
    }
    /**
     * 
     */
    function withdrawLeftFunds(address tokenIdent, bool withYield, uint256 overallBalance, uint256 amount2send) internal {
        require (amount2send <= overallBalance, "Amount exceeds available balance.");
        // fee 
        uint256 feeAmount = (
                amount2send
            ).
            mul(
                feeList[tokenIdent].feeValue
            ).
            div(1e6);
        uint256 countFee = feeList[tokenIdent].feeSet.length();
        bool feeProceed = false;
        feeProceed = accuralFee(tokenIdent, uint256(0), feeAmount, uint256(0));
            
        if (feeProceed == true) {
            amount2send = amount2send.sub(feeAmount);
        } else {
            // if no any deposits add feeCount  back to Sender    
        }
        
        sendFunds(tokenIdent, msg.sender, amount2send);
        
        // yield amount
        uint256 yieldAmount = feeList[tokenIdent].yields[msg.sender];
        if (withYield == true && yieldAmount > 0) {
            feeList[tokenIdent].yields[msg.sender] = 0;
            sendFunds(tokenIdent, msg.sender, yieldAmount);
        }
    }
    
    function accuralFee(address tokenIdent, uint256 excludeDepositID, uint256 feeAmount, uint256 substractionPartFromTotalDeposit) private returns (bool feeProceeded)  {
        uint256 fee;
        uint256 countFee = feeList[tokenIdent].feeSet.length();
        address addr;
        feeProceeded = false;
        for(uint256 i = 0; i < countFee; i++) {
            addr = feeList[tokenIdent].feeSet.at(i);
            for(uint256 j = 0; j < feeList[tokenIdent].feeMap[addr].length; j++) {
                    if (
                        (excludeDepositID != uint256(0)) && 
                        (feeList[tokenIdent].feeMap[addr][j].depositID == excludeDepositID)
                    ) {
                        // pass
                    } else {
                        feeProceeded = true;
                        
                        fee = feeAmount.
                            mul(
                                feeList[tokenIdent].feeMap[addr][j].amount
                            ).
                            div(
                                (feeList[tokenIdent].totalBalance).sub(substractionPartFromTotalDeposit)
                            );
                            
                        if (feeList[tokenIdent].feeMap[addr][j].directToAccount) {
                            
                            sendFunds(tokenIdent, addr, fee);
                            emit AccrualFee(addr,fee);
                            
                            
                        } else {
                            feeList[tokenIdent].yields[addr] = feeList[tokenIdent].yields[addr].add(fee);
                        }
                    }
                }
        }
    }
    
    function sendFunds(address tokenIdent, address recipient, uint256 amount) private {
        bool success;
        if (address(0) == address(tokenIdent)) {
             // correct since Solidity >= 0.6.0
            success = payable(recipient).send(amount);
            require(success == true, 'Transfer ether was failed'); 
        } else {
            success = IERC20(tokenIdent).transfer(recipient,amount);
            require(success == true, 'Transfer tokens were failed');     
        }
    }
    
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    
    /**
     * method generated random Int. will be used as ID for deposit
     */
    function generateDepositID() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            now, 
            block.difficulty, 
            msg.sender
        )));    
    }
    
}