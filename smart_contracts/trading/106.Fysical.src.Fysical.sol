pragma solidity 0.4.19;

// These import statements point at unmodified files from OpenZeppelin v1.6.0 (See https://github.com/OpenZeppelin/zeppelin-solidity/releases/tag/v1.6.0).
import "lib/zeppelin/token/ERC20/StandardToken.sol";
import "lib/zeppelin/math/SafeMath.sol";


// Fysical is a smart contract for introducing and trading arbitrarily-large data resources through Ethereum. Rather
// than recording a resource's data directly on the Ethereum blockchain, Fysical stores a reference to an off-chain,
// publicly-available encrypted copy of the resource. A buyer of this resource can download the encrypted copy and
// verify its byte count and checksum before proposing a trade with the resource's creator through Fysical. The
// resource's creator will provide the key to decrypt the resource when accepting the proposal. That key will itself be
// encrypted using a public key provided by the buyer in the offer.
//
// Creators can attach arbitrary meta-resources to resources and sets of resources. These meta-resources can be
// used for an purpose, including describing the compression/schema of the resource and describing the content in a
// formal or informal manner.
//
// Fysical also defines the ERC20-compatible Fysical token and controls transfers of Fysical tokens between Ethereum
// accounts. Trade proposal creators' can include a set of Fysical token transfers to execute when the proposal is
// accepted.
//
// This contract is designed to maintain a simple structure of data necessary for executing atomic trades of resources
// and Fysical tokens. Aside from the token operations offered by ERC20, all data stored in Fysical is described with
// 'struct' definitions. Three functions correspond to each struct. Using the 'Resource' struct as an example:
//
//      - 'createResource(...)' creates a 'Resource' object and stores it in the internal 'resourcesById' mapping. A
//          new id is generated during a call to this function, used as the key in the mapping, and returned to the
//          caller. The id of the first resource created will be 0, the second will be 1, and so on.
//
//      - 'getResourceById(...)' retrieves the 'Resource' object from the 'resourcesById' mapping and returns its
//          members to the caller.
//
//      - 'getResourceCount()' retrieves the total number 'Resource' objects created and returns it to the caller. Any
//          unsigned value lower than this count is a valid identifier for a 'Resource' object that has been created.
//
// The 'Proposal' is the root in the dependency tree of these structures. Each proposal refers to other data that has
// been created using the functions described above. When an Ethereum account creates a proposal, only one action
// relating to that proposal will follow. The creator of the 'ResourceSet' referenced in the proposal may accept or
// reject the proposal. Alternatively, the proposal's creator may withdraw the proposal before the resource
// set's creator has acted on the proposal.
//
// The atomicity of this final action allows parties to transact with a guarantee that the exchange of Fysical tokens
// and resource decryption keys will happen completely and simultaneously, without the possibility of just one operation
// failing to complete.
//
// The design of these structures and operations allows for de facto standards to emerge in choosing how to structure
// and distribute resources through Fysical. None of the functions defined in this contract are necessarily intended to
// be called directly from outside Ethereum, but including functions in this contract that may seem convenient today,
// may hinder the long-term usefulness of this trading model. It should be trivial for a user of Fysical to combine
// Fysical function calls into a smaller set of functions in another stateless Ethereum contract. Should these
// convenience methods prove less convenient in the future, it would be equally trivial to replace that stateless
// contract without affecting the data stored in the Fysical contract.
//
// Though tempting to include in Fysical, operations such as searching for resources with a certain schema, or
// de-duplicating the set of URIs can be handled flexibly and more affordable by observers of Fysical. The entire data
// content of Fysical can be trivially indexed with utilities that iterate though all the known identifiers for
// each 'struct'.
//
// Note that Fysical cannot guarantee that the content of a resource matches its description or that a decryption key
// will actually lead to a successful decryption. The permanent, immutable record of the intended content of a trade
// should serve as evidence for the developing reputations of participants in the market surrounding Fysical.
//
// Several structs in Fysical contain an unbounded array of items. Creators of these objects should take care to not
// include array lengths that would strain the practical block sizes and gas costs of Ethereum. Note that instead of
// referencing a large set of resources, a Resource Set creator has the option to create an archive of these resources
// and reference the archive on Fysical.
//
// Please note that ERC20 has a well-known issue surrounding approvals (See
// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729). Instead of executing "approve", please
// use "increaseApproval" and "decreaseApproval" to modify approval amounts.
contract Fysical is StandardToken {
    using SafeMath for uint256;

    // To increase consistency and reduce the opportunity for human error, the '*sById' mappings, '*Count' values,
    // 'get*ById' function declarations/implementations, and 'create*' function declarations/implementations have been
    // programmatically-generated based on the each struct's name, member types/names, and the comments sharing a line
    // with a member.
    //
    // This programmatic generation builds 'require' function calls based on the following rules:
    //      - 'string' values must have length > 0
    //      - 'bytes' and uint256[] values may have any length
    //      - 'uint256' values representing a quantity must be > 0 (identifiers and Ethereum block numbers do not represent a quantity)
    //
    // The implementation of 'createProposal' contains one operation not found in the other programmatically-generated
    // 'create*' functions, a call to 'transferTokensToEscrow'.
    //
    // None of the other members or functions have been programmatically generated.

    // See https://en.wikipedia.org/wiki/Uniform_Resource_Identifier.
    // The risk of preventing support for a future addition to the URI syntax outweighs the benefit of validating URI
    // values within this immutable smart contract, so readers of Uri values should expect values that do not conform
    // to the formal syntax of a URI.
    struct Uri {
        string value;
    }

    // A set of URIs may describe multiple methods to access a particular resource.
    struct UriSet {
        uint256[] uniqueUriIdsSortedAscending;    // each value must be key in 'urisById'
    }

    // See https://en.wikipedia.org/wiki/Checksum#Algorithms. The description of the algorithm referred to by each URI
    // in the set should give a reader enough information to interpret the 'value' member of a 'Checksum' object
    // referring to this algorithm object.
    struct ChecksumAlgorithm {
        uint256 descriptionUriSetId;    // must be key in 'uriSetsById'
    }

    // See https://en.wikipedia.org/wiki/Checksum. The 'resourceByteCount' indicates the number of bytes contained in
    // the resource. Though this is not strictly part of most common Checksum algorithms, its validation may also be
    // useful. The 'value' field should contain the expected output of passing the resource content to the checksum
    // algorithm.
    struct Checksum {
        uint256 algorithmId; // must be key in 'checksumAlgorithmsById'
        uint256 resourceByteCount;
        bytes value;
    }

    // See https://en.wikipedia.org/wiki/Encryption. The description of the algorithm referred to by each URI
    // in the set should give a reader enough information to access the content of an encrypted resource. The algorithm
    // may be a symmetric encryption algorithm or an asymmetric encryption algorithm
    struct EncryptionAlgorithm {
        uint256 descriptionUriSetId;    // must be key in 'uriSetsById'
    }

    // For each resource, an Ethereum account may describe a checksum for the encrypted content of a resource and a
    // checksum for the decrypted content of a resource. When the resource is encrypted with a null encryption
    // algorithm, the resource is effectively unencrypted, so these two checksums should be identical
    // (See https://en.wikipedia.org/wiki/Null_encryption).
    struct ChecksumPair {
        uint256 encryptedChecksumId; // must be key in 'checksumsById'
        uint256 decryptedChecksumId; // must be key in 'checksumsById'
    }

    // A 'Resource' is content accessible with each URI referenced in the 'uriSetId'. This content should be
    // encrypted with the algorithm described by the 'EncryptionAlgorithm' referenced in 'encryptionAlgorithmId'. Each
    // resource referenced in 'metaResourceSetId' should describe the decrypted content in some way.
    //
    // For example, if the decrypted content conforms to a Protocol Buffers schema, the corresponding proto definition
    // file should be included in the meta-resources. Likewise, that proto definition resource should refer to a
    // resource like https://en.wikipedia.org/wiki/Protocol_Buffers among its meta-resources.
    struct Resource {
        uint256 uriSetId;                // must be key in 'uriSetsById'
        uint256 encryptionAlgorithmId;   // must be key in 'encryptionAlgorithmsById'
        uint256 metaResourceSetId;       // must be key in 'resourceSetsById'
    }

    // See https://en.wikipedia.org/wiki/Public-key_cryptography. This value should be the public key used in an
    // asymmetric encryption operation. It should be useful for encrypting an resource destined for the holder of the
    // corresponding private key or for decrypting a resource encrypted with the corresponding private key.
    struct PublicKey {
        bytes value;
    }

    // A 'ResourceSet' groups together resources that may be part of a trade proposal involving Fysical tokens. The
    // creator of a 'ResourceSet' must include a public key for use in the encryption operations of creating and
    // accepting a trade proposal. The creator must also specify the encryption algorithm a proposal creator should
    // use along with this resource set creator's public key. Just as a single resource may have meta-resources
    // describing the content of a resource, a 'ResourceSet' may have resources describing the whole resource set.
    //
    // Creators should be careful to not include so many resources that an Ethereum transaction to accept a proposal
    // might run out of gas while storing the corresponding encrypted decryption keys.
    //
    // While developing reasonable filters for un-useful data in this collection, developers should choose a practical
    // maximum depth of traversal through the meta-resources, since an infinite loop is possible.
    struct ResourceSet {
        address creator;
        uint256 creatorPublicKeyId;                     // must be key in 'publicKeysById'
        uint256 proposalEncryptionAlgorithmId;          // must be key in 'encryptionAlgorithmsById'
        uint256[] uniqueResourceIdsSortedAscending;     // each value must be key in 'resourcesById'
        uint256 metaResourceSetId;                      // must be key in 'resourceSetsById'
    }

    // The creator of a trade proposal may include arbitrary content to be considered part of the agreement the
    // resource set is accepting. This may be useful for license agreements to be enforced within a jurisdiction
    // governing the trade partners. The content available through each URI in the set should be encrypted first with
    // the public key of a resource set's creator and then with the private key of a proposal's creator.
    struct Agreement {
        uint256 uriSetId;           // must be key in 'uriSetsById'
        uint256 checksumPairId;     // must be key in 'checksumPairsById'
    }

    // Many agreements may be grouped together in an 'AgreementSet'
    struct AgreementSet {
        uint256[] uniqueAgreementIdsSortedAscending; // each value must be key in 'agreementsById'
    }

    // A 'TokenTransfer' describes a transfer of tokens to occur between two Ethereum accounts.
    struct TokenTransfer {
        address source;
        address destination;
        uint256 tokenCount;
    }

    // Many token transfers may be grouped together in a "TokenTransferSet'
    struct TokenTransferSet {
        uint256[] uniqueTokenTransferIdsSortedAscending; // each value must be key in 'tokenTransfersById'
    }

    // A 'Proposal' describes the conditions for the atomic exchange of Fysical tokens and a keys to decrypt resources
    // in a resource set. The creator must specify the asymmetric encryption algorithm for use when accepting the
    // proposal, along with this creator's public key. The creator may specify arbitrary agreements that should be
    // considered a condition of the trade.
    //
    // During the execution of 'createProposal', the count of tokens specified in each token transfer will be transfered
    // from the specified source account to the account with the Ethereum address of 0. When the proposal state changes
    // to a final state, these tokens will be returned to the source accounts or tranfserred to the destination account.
    //
    // By including a 'minimumBlockNumberForWithdrawal' value later than the current Ethereum block, the proposal
    // creator can give the resource set creator a rough sense of how long the proposal will remain certainly
    // acceptable. This is particularly useful because the execution of an Ethereum transaction to accept a proposal
    // exposes the encrypted decryption keys to the Ethereum network regardless of whether the transaction succeeds.
    // Within the time frame that a proposal acceptance transaction will certainly succeed, the resource creator need
    // not be concerned with the possibility that an acceptance transaction might execute after a proposal withdrawal
    // submitted to the Ethereum network at approximately the same time.
    struct Proposal {
        uint256 minimumBlockNumberForWithdrawal;
        address creator;
        uint256 creatorPublicKeyId;                 // must be key in 'publicKeysById'
        uint256 acceptanceEncryptionAlgorithmId;    // must be key in 'encryptionAlgorithmsById'
        uint256 resourceSetId;                      // must be key in 'resourceSetsById'
        uint256 agreementSetId;                     // must be key in 'agreementSetsById'
        uint256 tokenTransferSetId;                 // must be key in 'tokenTransferSetsById'
    }

    // When created, the proposal is in the 'Pending' state. All other states are final states, so a proposal may change
    // state exactly one time based on a call to 'withdrawProposal', 'acceptProposal', or 'rejectProposal'.
    enum ProposalState {
        Pending,
        WithdrawnByCreator,
        RejectedByResourceSetCreator,
        AcceptedByResourceSetCreator
    }

    // solium would warn "Constant name 'name' doesn't follow the UPPER_CASE notation", but this public constant is
    // recommended by https://theethereum.wiki/w/index.php/ERC20_Token_Standard, so we'll disable warnings for the line.
    //
    /* solium-disable-next-line */
    string public constant name = "Fysical";

    // solium would warn "Constant name 'symbol' doesn't follow the UPPER_CASE notation", but this public constant is
    // recommended by https://theethereum.wiki/w/index.php/ERC20_Token_Standard, so we'll disable warnings for the line.
    //
    /* solium-disable-next-line */
    string public constant symbol = "FYS";

    // solium would warn "Constant name 'decimals' doesn't follow the UPPER_CASE notation", but this public constant is
    // recommended by https://theethereum.wiki/w/index.php/ERC20_Token_Standard, so we'll disable warnings for the line.
    //
    /* solium-disable-next-line */
    uint8 public constant decimals = 9;

    uint256 public constant ONE_BILLION = 1000000000;
    uint256 public constant ONE_QUINTILLION = 1000000000000000000;

    // See https://en.wikipedia.org/wiki/9,223,372,036,854,775,807
    uint256 public constant MAXIMUM_64_BIT_SIGNED_INTEGER_VALUE = 9223372036854775807;

    uint256 public constant EMPTY_PUBLIC_KEY_ID = 0;
    uint256 public constant NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID = 0;
    uint256 public constant NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID = 0;
    uint256 public constant NULL_ENCRYPTION_ALGORITHM_ID = 0;
    uint256 public constant EMPTY_RESOURCE_SET_ID = 0;

    mapping(uint256 => Uri) internal urisById;
    uint256 internal uriCount = 0;

    mapping(uint256 => UriSet) internal uriSetsById;
    uint256 internal uriSetCount = 0;

    mapping(uint256 => ChecksumAlgorithm) internal checksumAlgorithmsById;
    uint256 internal checksumAlgorithmCount = 0;

    mapping(uint256 => Checksum) internal checksumsById;
    uint256 internal checksumCount = 0;

    mapping(uint256 => EncryptionAlgorithm) internal encryptionAlgorithmsById;
    uint256 internal encryptionAlgorithmCount = 0;

    mapping(uint256 => ChecksumPair) internal checksumPairsById;
    uint256 internal checksumPairCount = 0;

    mapping(uint256 => Resource) internal resourcesById;
    uint256 internal resourceCount = 0;

    mapping(uint256 => PublicKey) internal publicKeysById;
    uint256 internal publicKeyCount = 0;

    mapping(uint256 => ResourceSet) internal resourceSetsById;
    uint256 internal resourceSetCount = 0;

    mapping(uint256 => Agreement) internal agreementsById;
    uint256 internal agreementCount = 0;

    mapping(uint256 => AgreementSet) internal agreementSetsById;
    uint256 internal agreementSetCount = 0;

    mapping(uint256 => TokenTransfer) internal tokenTransfersById;
    uint256 internal tokenTransferCount = 0;

    mapping(uint256 => TokenTransferSet) internal tokenTransferSetsById;
    uint256 internal tokenTransferSetCount = 0;

    mapping(uint256 => Proposal) internal proposalsById;
    uint256 internal proposalCount = 0;

    mapping(uint256 => ProposalState) internal statesByProposalId;

    mapping(uint256 => mapping(uint256 => bytes)) internal encryptedDecryptionKeysByProposalIdAndResourceId;

    mapping(address => mapping(uint256 => bool)) internal checksumPairAssignmentsByCreatorAndResourceId;

    mapping(address => mapping(uint256 => uint256)) internal checksumPairIdsByCreatorAndResourceId;

    function Fysical() public {
        assert(ProposalState(0) == ProposalState.Pending);

        // The total number of Fysical tokens is intended to be one billion, with the ability to express values with
        // nine decimals places of precision. The token values passed in ERC20 functions and operations involving
        // TokenTransfer operations must be counts of nano-Fysical tokens (one billionth of one Fysical token).
        //
        // See the initialization of the total supply in https://theethereum.wiki/w/index.php/ERC20_Token_Standard.

        assert(0 < ONE_BILLION);
        assert(0 < ONE_QUINTILLION);
        assert(MAXIMUM_64_BIT_SIGNED_INTEGER_VALUE > ONE_BILLION);
        assert(MAXIMUM_64_BIT_SIGNED_INTEGER_VALUE > ONE_QUINTILLION);
        assert(ONE_BILLION == uint256(10)**decimals);
        assert(ONE_QUINTILLION == ONE_BILLION.mul(ONE_BILLION));

        totalSupply_ = ONE_QUINTILLION;

        balances[msg.sender] = totalSupply_;

        // From "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transfer-1" on 2018-02-08 (commit cea1db05a3444870132ec3cb7dd78a244cba1805):
        //  "A token contract which creates new tokens SHOULD trigger a Transfer event with the _from address set to 0x0 when tokens are created."
        Transfer(0x0, msg.sender, balances[msg.sender]);

        // This mimics the behavior of the 'createPublicKey' external function.
        assert(EMPTY_PUBLIC_KEY_ID == publicKeyCount);
        publicKeysById[EMPTY_PUBLIC_KEY_ID] = PublicKey(new bytes(0));
        publicKeyCount = publicKeyCount.add(1);
        assert(1 == publicKeyCount);

        // This mimics the behavior of the 'createUri' external function.
        assert(NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID == uriCount);
        urisById[NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID] = Uri("https://en.wikipedia.org/wiki/Null_encryption");
        uriCount = uriCount.add(1);
        assert(1 == uriCount);

        // This mimics the behavior of the 'createUriSet' external function.
        assert(NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID == uriSetCount);
        uint256[] memory uniqueIdsSortedAscending = new uint256[](1);
        uniqueIdsSortedAscending[0] = NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID;
        validateIdSet(uniqueIdsSortedAscending, uriCount);
        uriSetsById[NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID] = UriSet(uniqueIdsSortedAscending);
        uriSetCount = uriSetCount.add(1);
        assert(1 == uriSetCount);

        // This mimics the behavior of the 'createEncryptionAlgorithm' external function.
        assert(NULL_ENCRYPTION_ALGORITHM_ID == encryptionAlgorithmCount);
        encryptionAlgorithmsById[NULL_ENCRYPTION_ALGORITHM_ID] = EncryptionAlgorithm(NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID);
        encryptionAlgorithmCount = encryptionAlgorithmCount.add(1);
        assert(1 == encryptionAlgorithmCount);

        // This mimics the behavior of the 'createResourceSet' external function, but allows for a self-reference in
        // the assignment of the 'metaResourceSetId' member, which the function would prohibit.
        assert(EMPTY_RESOURCE_SET_ID == resourceSetCount);
        resourceSetsById[EMPTY_RESOURCE_SET_ID] = ResourceSet(
            msg.sender,
            EMPTY_PUBLIC_KEY_ID,
            NULL_ENCRYPTION_ALGORITHM_ID,
            new uint256[](0),
            EMPTY_RESOURCE_SET_ID
        );
        resourceSetCount = resourceSetCount.add(1);
        assert(1 == resourceSetCount);
    }

    function getUriCount() external view returns (uint256) {
        return uriCount;
    }

    function getUriById(uint256 id) external view returns (string) {
        require(id < uriCount);

        Uri memory object = urisById[id];
        return object.value;
    }

    function getUriSetCount() external view returns (uint256) {
        return uriSetCount;
    }

    function getUriSetById(uint256 id) external view returns (uint256[]) {
        require(id < uriSetCount);

        UriSet memory object = uriSetsById[id];
        return object.uniqueUriIdsSortedAscending;
    }

    function getChecksumAlgorithmCount() external view returns (uint256) {
        return checksumAlgorithmCount;
    }

    function getChecksumAlgorithmById(uint256 id) external view returns (uint256) {
        require(id < checksumAlgorithmCount);

        ChecksumAlgorithm memory object = checksumAlgorithmsById[id];
        return object.descriptionUriSetId;
    }

    function getChecksumCount() external view returns (uint256) {
        return checksumCount;
    }

    function getChecksumById(uint256 id) external view returns (uint256, uint256, bytes) {
        require(id < checksumCount);

        Checksum memory object = checksumsById[id];
        return (object.algorithmId, object.resourceByteCount, object.value);
    }

    function getEncryptionAlgorithmCount() external view returns (uint256) {
        return encryptionAlgorithmCount;
    }

    function getEncryptionAlgorithmById(uint256 id) external view returns (uint256) {
        require(id < encryptionAlgorithmCount);

        EncryptionAlgorithm memory object = encryptionAlgorithmsById[id];
        return object.descriptionUriSetId;
    }

    function getChecksumPairCount() external view returns (uint256) {
        return checksumPairCount;
    }

    function getChecksumPairById(uint256 id) external view returns (uint256, uint256) {
        require(id < checksumPairCount);

        ChecksumPair memory object = checksumPairsById[id];
        return (object.encryptedChecksumId, object.decryptedChecksumId);
    }

    function getResourceCount() external view returns (uint256) {
        return resourceCount;
    }

    function getResourceById(uint256 id) external view returns (uint256, uint256, uint256) {
        require(id < resourceCount);

        Resource memory object = resourcesById[id];
        return (object.uriSetId, object.encryptionAlgorithmId, object.metaResourceSetId);
    }

    function getPublicKeyCount() external view returns (uint256) {
        return publicKeyCount;
    }

    function getPublicKeyById(uint256 id) external view returns (bytes) {
        require(id < publicKeyCount);

        PublicKey memory object = publicKeysById[id];
        return object.value;
    }

    function getResourceSetCount() external view returns (uint256) {
        return resourceSetCount;
    }

    function getResourceSetById(uint256 id) external view returns (address, uint256, uint256, uint256[], uint256) {
        require(id < resourceSetCount);

        ResourceSet memory object = resourceSetsById[id];
        return (object.creator, object.creatorPublicKeyId, object.proposalEncryptionAlgorithmId, object.uniqueResourceIdsSortedAscending, object.metaResourceSetId);
    }

    function getAgreementCount() external view returns (uint256) {
        return agreementCount;
    }

    function getAgreementById(uint256 id) external view returns (uint256, uint256) {
        require(id < agreementCount);

        Agreement memory object = agreementsById[id];
        return (object.uriSetId, object.checksumPairId);
    }

    function getAgreementSetCount() external view returns (uint256) {
        return agreementSetCount;
    }

    function getAgreementSetById(uint256 id) external view returns (uint256[]) {
        require(id < agreementSetCount);

        AgreementSet memory object = agreementSetsById[id];
        return object.uniqueAgreementIdsSortedAscending;
    }

    function getTokenTransferCount() external view returns (uint256) {
        return tokenTransferCount;
    }

    function getTokenTransferById(uint256 id) external view returns (address, address, uint256) {
        require(id < tokenTransferCount);

        TokenTransfer memory object = tokenTransfersById[id];
        return (object.source, object.destination, object.tokenCount);
    }

    function getTokenTransferSetCount() external view returns (uint256) {
        return tokenTransferSetCount;
    }

    function getTokenTransferSetById(uint256 id) external view returns (uint256[]) {
        require(id < tokenTransferSetCount);

        TokenTransferSet memory object = tokenTransferSetsById[id];
        return object.uniqueTokenTransferIdsSortedAscending;
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

    function getProposalById(uint256 id) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        require(id < proposalCount);

        Proposal memory object = proposalsById[id];
        return (object.minimumBlockNumberForWithdrawal, object.creator, object.creatorPublicKeyId, object.acceptanceEncryptionAlgorithmId, object.resourceSetId, object.agreementSetId, object.tokenTransferSetId);
    }

    function getStateByProposalId(uint256 proposalId) external view returns (ProposalState) {
        require(proposalId < proposalCount);

        return statesByProposalId[proposalId];
    }

    // Check to see if an Ethereum account has assigned a checksum for a particular resource.
    function hasAddressAssignedResourceChecksumPair(address address_, uint256 resourceId) external view returns (bool) {
        require(resourceId < resourceCount);

        return checksumPairAssignmentsByCreatorAndResourceId[address_][resourceId];
    }

    // Retrieve the checksum assigned assigned to particular resource
    function getChecksumPairIdByAssignerAndResourceId(address assigner, uint256 resourceId) external view returns (uint256) {
        require(resourceId < resourceCount);
        require(checksumPairAssignmentsByCreatorAndResourceId[assigner][resourceId]);

        return checksumPairIdsByCreatorAndResourceId[assigner][resourceId];
    }

    // Retrieve the encrypted key to decrypt a resource referenced by an accepted proposal.
    function getEncryptedResourceDecryptionKey(uint256 proposalId, uint256 resourceId) external view returns (bytes) {
        require(proposalId < proposalCount);
        require(ProposalState.AcceptedByResourceSetCreator == statesByProposalId[proposalId]);
        require(resourceId < resourceCount);

        uint256[] memory validResourceIds = resourceSetsById[proposalsById[proposalId].resourceSetId].uniqueResourceIdsSortedAscending;
        require(0 < validResourceIds.length);

        if (1 == validResourceIds.length) {
            require(resourceId == validResourceIds[0]);

        } else {
            uint256 lowIndex = 0;
            uint256 highIndex = validResourceIds.length.sub(1);
            uint256 middleIndex = lowIndex.add(highIndex).div(2);

            while (resourceId != validResourceIds[middleIndex]) {
                require(lowIndex <= highIndex);

                if (validResourceIds[middleIndex] < resourceId) {
                    lowIndex = middleIndex.add(1);
                } else {
                    highIndex = middleIndex.sub(1);
                }

                middleIndex = lowIndex.add(highIndex).div(2);
            }
        }

        return encryptedDecryptionKeysByProposalIdAndResourceId[proposalId][resourceId];
    }

    function createUri(
        string value
    ) external returns (uint256)
    {
        require(0 < bytes(value).length);

        uint256 id = uriCount;
        uriCount = id.add(1);
        urisById[id] = Uri(
            value
        );

        return id;
    }

    function createUriSet(
        uint256[] uniqueUriIdsSortedAscending
    ) external returns (uint256)
    {
        validateIdSet(uniqueUriIdsSortedAscending, uriCount);

        uint256 id = uriSetCount;
        uriSetCount = id.add(1);
        uriSetsById[id] = UriSet(
            uniqueUriIdsSortedAscending
        );

        return id;
    }

    function createChecksumAlgorithm(
        uint256 descriptionUriSetId
    ) external returns (uint256)
    {
        require(descriptionUriSetId < uriSetCount);

        uint256 id = checksumAlgorithmCount;
        checksumAlgorithmCount = id.add(1);
        checksumAlgorithmsById[id] = ChecksumAlgorithm(
            descriptionUriSetId
        );

        return id;
    }

    function createChecksum(
        uint256 algorithmId,
        uint256 resourceByteCount,
        bytes value
    ) external returns (uint256)
    {
        require(algorithmId < checksumAlgorithmCount);
        require(0 < resourceByteCount);

        uint256 id = checksumCount;
        checksumCount = id.add(1);
        checksumsById[id] = Checksum(
            algorithmId,
            resourceByteCount,
            value
        );

        return id;
    }

    function createEncryptionAlgorithm(
        uint256 descriptionUriSetId
    ) external returns (uint256)
    {
        require(descriptionUriSetId < uriSetCount);

        uint256 id = encryptionAlgorithmCount;
        encryptionAlgorithmCount = id.add(1);
        encryptionAlgorithmsById[id] = EncryptionAlgorithm(
            descriptionUriSetId
        );

        return id;
    }

    function createChecksumPair(
        uint256 encryptedChecksumId,
        uint256 decryptedChecksumId
    ) external returns (uint256)
    {
        require(encryptedChecksumId < checksumCount);
        require(decryptedChecksumId < checksumCount);

        uint256 id = checksumPairCount;
        checksumPairCount = id.add(1);
        checksumPairsById[id] = ChecksumPair(
            encryptedChecksumId,
            decryptedChecksumId
        );

        return id;
    }

    function createResource(
        uint256 uriSetId,
        uint256 encryptionAlgorithmId,
        uint256 metaResourceSetId
    ) external returns (uint256)
    {
        require(uriSetId < uriSetCount);
        require(encryptionAlgorithmId < encryptionAlgorithmCount);
        require(metaResourceSetId < resourceSetCount);

        uint256 id = resourceCount;
        resourceCount = id.add(1);
        resourcesById[id] = Resource(
            uriSetId,
            encryptionAlgorithmId,
            metaResourceSetId
        );

        return id;
    }

    function createPublicKey(
        bytes value
    ) external returns (uint256)
    {
        uint256 id = publicKeyCount;
        publicKeyCount = id.add(1);
        publicKeysById[id] = PublicKey(
            value
        );

        return id;
    }

    function createResourceSet(
        uint256 creatorPublicKeyId,
        uint256 proposalEncryptionAlgorithmId,
        uint256[] uniqueResourceIdsSortedAscending,
        uint256 metaResourceSetId
    ) external returns (uint256)
    {
        require(creatorPublicKeyId < publicKeyCount);
        require(proposalEncryptionAlgorithmId < encryptionAlgorithmCount);
        validateIdSet(uniqueResourceIdsSortedAscending, resourceCount);
        require(metaResourceSetId < resourceSetCount);

        uint256 id = resourceSetCount;
        resourceSetCount = id.add(1);
        resourceSetsById[id] = ResourceSet(
            msg.sender,
            creatorPublicKeyId,
            proposalEncryptionAlgorithmId,
            uniqueResourceIdsSortedAscending,
            metaResourceSetId
        );

        return id;
    }

    function createAgreement(
        uint256 uriSetId,
        uint256 checksumPairId
    ) external returns (uint256)
    {
        require(uriSetId < uriSetCount);
        require(checksumPairId < checksumPairCount);

        uint256 id = agreementCount;
        agreementCount = id.add(1);
        agreementsById[id] = Agreement(
            uriSetId,
            checksumPairId
        );

        return id;
    }

    function createAgreementSet(
        uint256[] uniqueAgreementIdsSortedAscending
    ) external returns (uint256)
    {
        validateIdSet(uniqueAgreementIdsSortedAscending, agreementCount);

        uint256 id = agreementSetCount;
        agreementSetCount = id.add(1);
        agreementSetsById[id] = AgreementSet(
            uniqueAgreementIdsSortedAscending
        );

        return id;
    }

    function createTokenTransfer(
        address source,
        address destination,
        uint256 tokenCount
    ) external returns (uint256)
    {
        require(address(0) != source);
        require(address(0) != destination);
        require(0 < tokenCount);

        uint256 id = tokenTransferCount;
        tokenTransferCount = id.add(1);
        tokenTransfersById[id] = TokenTransfer(
            source,
            destination,
            tokenCount
        );

        return id;
    }

    function createTokenTransferSet(
        uint256[] uniqueTokenTransferIdsSortedAscending
    ) external returns (uint256)
    {
        validateIdSet(uniqueTokenTransferIdsSortedAscending, tokenTransferCount);

        uint256 id = tokenTransferSetCount;
        tokenTransferSetCount = id.add(1);
        tokenTransferSetsById[id] = TokenTransferSet(
            uniqueTokenTransferIdsSortedAscending
        );

        return id;
    }

    function createProposal(
        uint256 minimumBlockNumberForWithdrawal,
        uint256 creatorPublicKeyId,
        uint256 acceptanceEncryptionAlgorithmId,
        uint256 resourceSetId,
        uint256 agreementSetId,
        uint256 tokenTransferSetId
    ) external returns (uint256)
    {
        require(creatorPublicKeyId < publicKeyCount);
        require(acceptanceEncryptionAlgorithmId < encryptionAlgorithmCount);
        require(resourceSetId < resourceSetCount);
        require(agreementSetId < agreementSetCount);
        require(tokenTransferSetId < tokenTransferSetCount);

        transferTokensToEscrow(msg.sender, tokenTransferSetId);

        uint256 id = proposalCount;
        proposalCount = id.add(1);
        proposalsById[id] = Proposal(
            minimumBlockNumberForWithdrawal,
            msg.sender,
            creatorPublicKeyId,
            acceptanceEncryptionAlgorithmId,
            resourceSetId,
            agreementSetId,
            tokenTransferSetId
        );

        return id;
    }

    // Each Ethereum account may assign a 'ChecksumPair' to a resource exactly once. This ensures that each claim that a
    // checksum should match a resource is attached to a particular authority. This operation is not bound to the
    // creation of the resource because the resource's creator may not know the checksum when creating the resource.
    function assignResourceChecksumPair(
        uint256 resourceId,
        uint256 checksumPairId
    ) external
    {
        require(resourceId < resourceCount);
        require(checksumPairId < checksumPairCount);
        require(false == checksumPairAssignmentsByCreatorAndResourceId[msg.sender][resourceId]);

        checksumPairIdsByCreatorAndResourceId[msg.sender][resourceId] = checksumPairId;
        checksumPairAssignmentsByCreatorAndResourceId[msg.sender][resourceId] = true;
    }

    // This function moves a proposal to a final state of `WithdrawnByCreator' and returns tokens to the sources
    // described by the proposal's transfers.
    function withdrawProposal(
        uint256 proposalId
    ) external
    {
        require(proposalId < proposalCount);
        require(ProposalState.Pending == statesByProposalId[proposalId]);

        Proposal memory proposal = proposalsById[proposalId];
        require(msg.sender == proposal.creator);
        require(block.number >= proposal.minimumBlockNumberForWithdrawal);

        returnTokensFromEscrow(proposal.creator, proposal.tokenTransferSetId);
        statesByProposalId[proposalId] = ProposalState.WithdrawnByCreator;
    }

    // This function moves a proposal to a final state of `RejectedByResourceSetCreator' and returns tokens to the sources
    // described by the proposal's transfers.
    function rejectProposal(
        uint256 proposalId
    ) external
    {
        require(proposalId < proposalCount);
        require(ProposalState.Pending == statesByProposalId[proposalId]);

        Proposal memory proposal = proposalsById[proposalId];
        require(msg.sender == resourceSetsById[proposal.resourceSetId].creator);

        returnTokensFromEscrow(proposal.creator, proposal.tokenTransferSetId);
        statesByProposalId[proposalId] = ProposalState.RejectedByResourceSetCreator;
    }

    // This function moves a proposal to a final state of `RejectedByResourceSetCreator' and sends tokens to the
    // destinations described by the proposal's transfers.
    //
    // The caller should encrypt each decryption key corresponding
    // to each resource in the proposal's resource set first with the public key of the proposal's creator and then with
    // the private key assoicated with the public key referenced in the resource set. The caller should concatenate
    // these encrypted values and pass the resulting byte array as 'concatenatedResourceDecryptionKeys'.
    // The length of each encrypted decryption key should be provided in the 'concatenatedResourceDecryptionKeyLengths'.
    // The index of each value in 'concatenatedResourceDecryptionKeyLengths' must correspond to an index in the resource
    // set referenced by the proposal.
    function acceptProposal(
        uint256 proposalId,
        bytes concatenatedResourceDecryptionKeys,
        uint256[] concatenatedResourceDecryptionKeyLengths
    ) external
    {
        require(proposalId < proposalCount);
        require(ProposalState.Pending == statesByProposalId[proposalId]);

        Proposal memory proposal = proposalsById[proposalId];
        require(msg.sender == resourceSetsById[proposal.resourceSetId].creator);

        storeEncryptedDecryptionKeys(
            proposalId,
            concatenatedResourceDecryptionKeys,
            concatenatedResourceDecryptionKeyLengths
        );

        transferTokensFromEscrow(proposal.tokenTransferSetId);

        statesByProposalId[proposalId] = ProposalState.AcceptedByResourceSetCreator;
    }

    function validateIdSet(uint256[] uniqueIdsSortedAscending, uint256 idCount) private pure {
        if (0 < uniqueIdsSortedAscending.length) {

            uint256 id = uniqueIdsSortedAscending[0];
            require(id < idCount);

            uint256 previousId = id;
            for (uint256 index = 1; index < uniqueIdsSortedAscending.length; index = index.add(1)) {
                id = uniqueIdsSortedAscending[index];
                require(id < idCount);
                require(previousId < id);

                previousId = id;
            }
        }
    }

    function transferTokensToEscrow(address proposalCreator, uint256 tokenTransferSetId) private {
        assert(tokenTransferSetId < tokenTransferSetCount);
        assert(address(0) != proposalCreator);

        uint256[] memory tokenTransferIds = tokenTransferSetsById[tokenTransferSetId].uniqueTokenTransferIdsSortedAscending;
        for (uint256 index = 0; index < tokenTransferIds.length; index = index.add(1)) {
            uint256 tokenTransferId = tokenTransferIds[index];
            assert(tokenTransferId < tokenTransferCount);

            TokenTransfer memory tokenTransfer = tokenTransfersById[tokenTransferId];
            assert(0 < tokenTransfer.tokenCount);
            assert(address(0) != tokenTransfer.source);
            assert(address(0) != tokenTransfer.destination);

            require(tokenTransfer.tokenCount <= balances[tokenTransfer.source]);

            if (tokenTransfer.source != proposalCreator) {
                require(tokenTransfer.tokenCount <= allowed[tokenTransfer.source][proposalCreator]);

                allowed[tokenTransfer.source][proposalCreator] = allowed[tokenTransfer.source][proposalCreator].sub(tokenTransfer.tokenCount);
            }

            balances[tokenTransfer.source] = balances[tokenTransfer.source].sub(tokenTransfer.tokenCount);
            balances[address(0)] = balances[address(0)].add(tokenTransfer.tokenCount);

            Transfer(tokenTransfer.source, address(0), tokenTransfer.tokenCount);
        }
    }

    function returnTokensFromEscrow(address proposalCreator, uint256 tokenTransferSetId) private {
        assert(tokenTransferSetId < tokenTransferSetCount);
        assert(address(0) != proposalCreator);

        uint256[] memory tokenTransferIds = tokenTransferSetsById[tokenTransferSetId].uniqueTokenTransferIdsSortedAscending;
        for (uint256 index = 0; index < tokenTransferIds.length; index = index.add(1)) {
            uint256 tokenTransferId = tokenTransferIds[index];
            assert(tokenTransferId < tokenTransferCount);

            TokenTransfer memory tokenTransfer = tokenTransfersById[tokenTransferId];
            assert(0 < tokenTransfer.tokenCount);
            assert(address(0) != tokenTransfer.source);
            assert(address(0) != tokenTransfer.destination);
            assert(tokenTransfer.tokenCount <= balances[address(0)]);

            balances[tokenTransfer.source] = balances[tokenTransfer.source].add(tokenTransfer.tokenCount);
            balances[address(0)] = balances[address(0)].sub(tokenTransfer.tokenCount);

            Transfer(address(0), tokenTransfer.source, tokenTransfer.tokenCount);
        }
    }

    function transferTokensFromEscrow(uint256 tokenTransferSetId) private {
        assert(tokenTransferSetId < tokenTransferSetCount);

        uint256[] memory tokenTransferIds = tokenTransferSetsById[tokenTransferSetId].uniqueTokenTransferIdsSortedAscending;
        for (uint256 index = 0; index < tokenTransferIds.length; index = index.add(1)) {
            uint256 tokenTransferId = tokenTransferIds[index];
            assert(tokenTransferId < tokenTransferCount);

            TokenTransfer memory tokenTransfer = tokenTransfersById[tokenTransferId];
            assert(0 < tokenTransfer.tokenCount);
            assert(address(0) != tokenTransfer.source);
            assert(address(0) != tokenTransfer.destination);

            balances[address(0)] = balances[address(0)].sub(tokenTransfer.tokenCount);
            balances[tokenTransfer.destination] = balances[tokenTransfer.destination].add(tokenTransfer.tokenCount);
            Transfer(address(0), tokenTransfer.destination, tokenTransfer.tokenCount);
        }
    }

    function storeEncryptedDecryptionKeys(
        uint256 proposalId,
        bytes concatenatedEncryptedResourceDecryptionKeys,
        uint256[] encryptedResourceDecryptionKeyLengths
    ) private
    {
        assert(proposalId < proposalCount);

        uint256 resourceSetId = proposalsById[proposalId].resourceSetId;
        assert(resourceSetId < resourceSetCount);

        ResourceSet memory resourceSet = resourceSetsById[resourceSetId];
        require(resourceSet.uniqueResourceIdsSortedAscending.length == encryptedResourceDecryptionKeyLengths.length);

        uint256 concatenatedEncryptedResourceDecryptionKeysIndex = 0;
        for (uint256 resourceIndex = 0; resourceIndex < encryptedResourceDecryptionKeyLengths.length; resourceIndex = resourceIndex.add(1)) {
            bytes memory encryptedResourceDecryptionKey = new bytes(encryptedResourceDecryptionKeyLengths[resourceIndex]);
            require(0 < encryptedResourceDecryptionKey.length);

            for (uint256 encryptedResourceDecryptionKeyIndex = 0; encryptedResourceDecryptionKeyIndex < encryptedResourceDecryptionKey.length; encryptedResourceDecryptionKeyIndex = encryptedResourceDecryptionKeyIndex.add(1)) {
                require(concatenatedEncryptedResourceDecryptionKeysIndex < concatenatedEncryptedResourceDecryptionKeys.length);
                encryptedResourceDecryptionKey[encryptedResourceDecryptionKeyIndex] = concatenatedEncryptedResourceDecryptionKeys[concatenatedEncryptedResourceDecryptionKeysIndex];
                concatenatedEncryptedResourceDecryptionKeysIndex = concatenatedEncryptedResourceDecryptionKeysIndex.add(1);
            }

            uint256 resourceId = resourceSet.uniqueResourceIdsSortedAscending[resourceIndex];
            assert(resourceId < resourceCount);

            encryptedDecryptionKeysByProposalIdAndResourceId[proposalId][resourceId] = encryptedResourceDecryptionKey;
        }

        require(concatenatedEncryptedResourceDecryptionKeysIndex == concatenatedEncryptedResourceDecryptionKeys.length);
    }
}
