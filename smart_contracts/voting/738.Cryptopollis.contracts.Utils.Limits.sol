// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 */
abstract contract Limits {
    uint questionLengthLimit;
    uint optionLengthLimit;
    uint optionArrayLengthLimit;

    function setQuestionLengthLimit(uint limit) internal {
        questionLengthLimit = limit;
    }
    function setOptionLengthLimit(uint limit) internal {
        optionLengthLimit = limit;
    }
    function setOptionArrayLengthLimit(uint limit) internal {
        optionArrayLengthLimit = limit;
    }
    /**
     * @notice Returns whether voter already voted the poll
     * @dev 
    */
    function checkLimits(string memory question, string[] memory options) public view returns (bool) {
        
        require(options.length <= questionLengthLimit, "Array length is too long");
        require(bytes(question).length <= optionArrayLengthLimit, "Question length is too long");
        for (uint i=0; i<options.length;i++) {
            require(bytes(options[i]).length <= optionLengthLimit, "Option length is too long");
        }
        return true;
    }
}
