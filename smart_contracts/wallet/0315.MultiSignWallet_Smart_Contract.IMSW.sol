

interface IMSW {

    function submti(address to , uint value , bytes calldata data) external;
    
    function approve(uint txId) external;

    function unapprove(uint txId) external;

    function execute(uint txId) external;

}