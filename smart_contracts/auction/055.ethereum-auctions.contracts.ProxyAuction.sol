// taken from parity multisig wallet
pragma solidity ^0.4.18;

contract ProxyAuction {
    address lib;
    function ProxyAuction(address _lib) public {
        lib = _lib;
        }

    // delegate any contract calls to
    // the library
    function() external payable {
        uint size = msg.data.length;
        bytes32 m_data = _malloc(size);

        assembly {
            calldatacopy(m_data, 0x0, size)
        }

        bytes32 m_result = _call(m_data, size);

        assembly {
            return(m_result, 0x20)
        }
    }

    // allocate the given size in memory and return
    // the pointer
    function _malloc(uint size) private returns(bytes32) {
        bytes32 m_data;

        assembly {
            // Get free memory pointer and update it
            m_data := mload(0x40)
            mstore(0x40, add(m_data, size))
        }

        return m_data;
    }

    // make a delegatecall to the target contract, given the
    // data located at m_data, that has the given size
    //
    // @returns A pointer to memory which contain the 32 first bytes
    //          of the delegatecall output
    function _call(bytes32 m_data, uint size) private returns(bytes32) {
        address target = lib;
        bytes32 m_result = _malloc(32);
        bool failed;

        assembly {
            failed := iszero(delegatecall(sub(gas, 10000), target, m_data, size, m_result, 0x20))
        }

        require(!failed);
        return m_result;
    }
}