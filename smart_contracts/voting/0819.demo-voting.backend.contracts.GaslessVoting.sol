// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Sapphire} from '@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol';
import {EIP155Signer} from '@oasisprotocol/sapphire-contracts/contracts/EIP155Signer.sol';
import {SignatureRSV,EthereumUtils} from '@oasisprotocol/sapphire-contracts/contracts/EthereumUtils.sol';
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

import {PollACLv1, ProposalId, AcceptsProxyVotes, ProposalParams} from "./Types.sol";

struct VotingRequest {
    address voter;
    bytes32 proposalId;
    uint256 choiceId;
}

struct EthereumKeypair {
    address addr;
    bytes32 secret;
    uint64 nonce;
}

contract GaslessVoting is IERC165 {
    address private immutable OWNER;

    EthereumKeypair[] private keypairs;

    mapping(address => uint256) keypair_addresses;

    bytes32 immutable private encryptionSecret;

    AcceptsProxyVotes public DAO;

    // EIP-712 parameters
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    string public constant VOTINGREQUEST_TYPE = "VotingRequest(address voter,bytes32 proposalId,uint256 choiceId)";
    bytes32 public constant VOTINGREQUEST_TYPEHASH = keccak256(bytes(VOTINGREQUEST_TYPE));
    string public constant CREATEPROPOSAL_TYPE = "CreateProposal(address creator,string ipfsHash,uint16 numChoices,bool publishVotes)";
    bytes32 public constant CREATEPROPOSAL_TYPEHASH = keccak256(bytes(CREATEPROPOSAL_TYPE));
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor (address in_owner)
        payable
    {
        OWNER = (in_owner == address(0)) ? msg.sender : in_owner;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("DAOv1.GaslessVoting"),
            keccak256("1"),
            block.chainid,
            address(this)
        ));

        // Generate an encryption key, it is only used by this contract to encrypt data for itself
        encryptionSecret = bytes32(Sapphire.randomBytes(32, ""));

        // Generate a keypair which will be used to submit transactions to invoke this contract
        //(signerAddr, signerSecret) = EthereumUtils.generateKeypair();
        address signerAddr = internal_addKeypair();

        // Forward on any gas money sent while deploying
        if( msg.value > 0 ) {
            payable(signerAddr).transfer(msg.value);
        }
    }

    /**
     * Add a random keypair to the list
     */
    function internal_addKeypair()
        internal
        returns (address)
    {
        (address signerAddr, bytes32 signerSecret) = EthereumUtils.generateKeypair();

        keypair_addresses[signerAddr] = keypairs.length + 1;

        keypairs.push(EthereumKeypair(
            signerAddr,
            signerSecret,
            0
        ));

        return signerAddr;
    }

    /**
     * Select a random keypair
     */
    function internal_randomKeypair()
        internal view
        returns (EthereumKeypair storage)
    {
        uint16 x = uint16(bytes2(Sapphire.randomBytes(2, "")));

        return keypairs[x % keypairs.length];
    }

    /**
     * Select a keypair given its address
     * Reverts if it's not one of our keypairs
     * @param addr Ethererum public address
     */
    function internal_keypairByAddress(address addr)
        internal view
        returns (EthereumKeypair storage)
    {
        uint256 offset = keypair_addresses[addr];

        require( offset != 0 );

        return keypairs[offset - 1];
    }

    /**
     * Reimburse msg.sender for the gas spent
     * @param gas_start Statring gas measurement
     */
    function internal_reimburse(uint gas_start)
        internal
    {
        uint my_balance = address(this).balance;

        if( my_balance > 0 )
        {
            uint gas_cost = (gasleft() - gas_start) + 20000;

            uint to_transfer = (gas_cost * tx.gasprice) + block.basefee;

            to_transfer = to_transfer > my_balance ? my_balance : to_transfer;

            if( to_transfer > 0 )
            {
                payable(msg.sender).transfer(to_transfer);
            }
        }
    }

    event KeypairCreated(address addr);

    /**
     * Create a random keypair, sending some gas to it
     */
    function addKeypair ()
        external payable
    {
        require( msg.sender == OWNER );

        address addr = internal_addKeypair();

        emit KeypairCreated(addr);

        if( msg.value > 0 )
        {
            payable(addr).transfer(msg.value);
        }
    }

    function listAddresses ()
        external view
        returns (address[] memory)
    {
        uint kpl = keypairs.length;

        address[] memory addrs = new address[](kpl);

        for( uint i = 0; i < kpl; i++ )
        {
            addrs[i] = keypairs[i].addr;
        }

        return addrs;
    }

    function supportsInterface(bytes4 interfaceID)
        external pure
        returns (bool)
    {
        return interfaceID == 0x01ffc9a7 // ERC-165
            || interfaceID == this.makeVoteTransaction.selector;
    }

    function setDAO(AcceptsProxyVotes in_dao)
        external
    {
        require( msg.sender == OWNER );

        // Can only be set once
        require( address(DAO) == address(0) );

        DAO = in_dao;
    }

    function getChainId()
        external view
        returns (uint256)
    {
        return block.chainid;
    }

    /**
     * Validate a users voting request, then give them a signed transaction to commit the vote
     *
     * The signed transaction invokes `submitEncryptedVote`, which is unmodifiable by the user
     * and hides all info about what their address is, which ballot they were voting on and
     * what their vote was.
     *
     * @param gasPrice Which gas price to use when submitting transaction
     * @param request Voting Request
     * @param rsv EIP-712 signature for request
     * @return output Signed transaction to submit via eth_sendRawTransaction
     */
    function makeVoteTransaction(
        uint256 gasPrice,
        VotingRequest calldata request,
        SignatureRSV calldata rsv
    )
        external view
        returns (bytes memory output)
    {
        // User must be able to vote on the poll
        // so we don't waste gas submitting invalid transactions
        require( DAO.getACL().canVoteOnPoll(address(DAO), ProposalId.wrap(request.proposalId), request.voter) );

        // Validate EIP-712 signed voting request
        bytes32 requestDigest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                VOTINGREQUEST_TYPEHASH,
                request.voter,
                request.proposalId,
                request.choiceId
            ))
        ));
        require( request.voter == ecrecover(requestDigest, uint8(rsv.v), rsv.r, rsv.s), "Invalid Request!" );

        // Encrypt request to authenticate it when we're invoked again
        bytes32 ciphertextNonce = keccak256(abi.encodePacked(encryptionSecret, requestDigest));

        // Inner call to DAO contract
        bytes memory innercall = abi.encodeWithSelector(DAO.proxyVote.selector, request.voter, ProposalId.wrap(request.proposalId), request.choiceId);

        // Encrypt inner call, with DAO address as target
        bytes memory ciphertext = Sapphire.encrypt(encryptionSecret, ciphertextNonce, abi.encode(address(DAO), innercall), "");

        // Call will invoke the proxy
        bytes memory data = abi.encodeWithSelector(this.proxy.selector, ciphertextNonce, ciphertext);

        // TODO: simulate query to get gas limit? then increase by 20%

        EthereumKeypair memory kp = internal_randomKeypair();

        // Return signed transaction invoking 'submitEncryptedVote'
        return EIP155Signer.sign(kp.addr, kp.secret, EIP155Signer.EthTx({
            nonce: kp.nonce,
            gasPrice: gasPrice,
            gasLimit: 250000,
            to: address(this),
            value: 0,
            data: data,
            chainId: block.chainid
        }));
    }

    function makeProposalTransaction(
        uint256 gasPrice,
        address creator,
        ProposalParams calldata request,
        SignatureRSV calldata rsv
    )
        external view
        returns (bytes memory)
    {
        require( DAO.getACL().canCreatePoll(address(DAO), creator), "ACL disallows poll creation" );

        bytes32 requestDigest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                CREATEPROPOSAL_TYPEHASH,
                creator,
                keccak256(abi.encodePacked(request.ipfsHash)),
                request.numChoices,
                request.publishVotes
            ))
        ));
        require( creator == ecrecover(requestDigest, uint8(rsv.v), rsv.r, rsv.s), "Invalid Request!" );

        // Encrypt request to authenticate it when we're invoked again
        bytes32 ciphertextNonce = keccak256(abi.encodePacked(encryptionSecret, requestDigest));

        // Inner call to DAO contract
        bytes memory innercall = abi.encodeWithSelector(DAO.createProposal.selector, request);

        // Encrypt inner call, with DAO address as target
        bytes memory ciphertext = Sapphire.encrypt(encryptionSecret, ciphertextNonce, abi.encode(address(DAO), innercall), "");

        // TODO: simulate query to get gas limit? then increase by 20%

        EthereumKeypair memory kp = internal_randomKeypair();

        // Return signed transaction invoking 'submitEncryptedVote'
        return EIP155Signer.sign(kp.addr, kp.secret, EIP155Signer.EthTx({
            nonce: kp.nonce,
            gasPrice: gasPrice,
            gasLimit: 1000000,
            to: address(this),
            value: 0,
            data: abi.encodeWithSelector(this.proxy.selector, ciphertextNonce, ciphertext),
            chainId: block.chainid
        }));
    }

    function proxy(bytes32 ciphertextNonce, bytes memory data)
        external payable
    {
        uint gas_start = gasleft();

        EthereumKeypair storage kp = internal_keypairByAddress(msg.sender);

        (address addr, bytes memory subcall_data) = abi.decode(Sapphire.decrypt(encryptionSecret, ciphertextNonce, data, ""), (address, bytes));

        (bool success,) = addr.call{value: msg.value}(subcall_data);

        require( success );

        kp.nonce += 1;

        internal_reimburse(gas_start);
    }

    /**
     * Allow the owner to withdraw excess funds from the Signing Account
     *
     * TODO: use signed queries?
     *
     * @param nonce transaction nonce
     * @param gasPrice gas price to use when submitting transaction
     * @param amount amount to withdraw
     * @param rsv signature R, S & V values
     * @return transaction signed by Signing Account
     */
    /*
    function withdraw(address signer, uint64 nonce, uint256 gasPrice, uint256 amount, SignatureRSV calldata rsv)
        external view
        returns (bytes memory transaction)
    {
        bytes32 inner_digest = keccak256(abi.encode(address(this), nonce, gasPrice, amount));

        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner_digest));

        require( OWNER == ecrecover(digest, uint8(rsv.v), rsv.r, rsv.s), "Not owner account!" );

        require( keypair_addresses[signer] != 0 );

        EthereumKeypair memory kp = keypairs[keypair_addresses[signer]];

        return EIP155Signer.sign(kp.addr, kp.secret, EIP155Signer.EthTx({
            nonce: nonce,
            gasPrice: gasPrice,
            gasLimit: 250000,
            to: OWNER,
            value: amount,
            data: "",
            chainId: block.chainid
        }));
    }
    */
}