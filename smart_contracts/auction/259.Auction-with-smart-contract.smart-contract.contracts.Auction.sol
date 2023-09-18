// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/*
    NGỮ CẢNH:
    - mọi người có ví metamask có thể vào tạo phiên đấu giá và lên các sản phẩm muốn đấu giá. sau khi xong thì họ phải gửi các vật phẩm đó
    lên cho chúng tôi kiểm tra và đảm bảo xác nhận vật phẩm là thật và chúng tôi sẽ dùng chức năng với quyền admin để xác nhận phòng đấu giá đó hợp lệ
    và có thể mở phiên đấu giá.
    - sau khi đấu giá xong thì chúng tôi sẽ ăn 10% hoa hồng của tổng tiền mà phòng đó đấu giá thành công.
    - người đấu giá thành công sẽ phải lên công ty chúng tôi nhận vật phẩm mà họ đấu giá

    CÁC CHỨC NĂNG:
    - tạo phiên đấu giá (mỗi người có vĩ metamask đều có thể vào và mở phiên đấu giá)
    - xác nhận đấu giá hợp lệ (vào với cơ chế admin để xác nhận phòng đấu giá là hợp lệ và có thể mở phiên đấu giá)
    - mở đấu giá
    - đóng đấu giá (kết thúc phiên đấu giá, tiền người nào cao hơn sẽ nhận hàng và trừ trực tiếp lúc thực hiện việc trừ tiền mà ví đó ko đủ tiền thì vật phẩm đó sẽ ở trạng
    thái chưa hợp lệ và việc này sẽ là cơ chế vật lý trao đổi với 2 bên người đấu giá và người tạo phiên đấu giá)
    - đấu giá
*/

contract Auction {
    string secret = "daylamatkhau";
    mapping(address => Room) public rooms;
    uint countRoom;

    SessionInfo[] public sessionsOpen;
    uint public countSessionOpen;

    struct Room{
        address addressUser;
        mapping(uint => Session) sessions;
        uint countSession;
    }

    struct Session{
        uint id;
        string name;
        mapping(uint => Product) products;
        uint totalProduct;
        uint openTime;
        uint closeTime;
        uint totalPrice;
        SessionStatus status;
    }

    struct SessionInfo{
        uint id;
        string name;
        uint totalProduct;
        uint openTime;
        uint closeTime;
        SessionStatus status;
        address ownerSession;
        uint totalPrice;
    }

    struct Product {
        uint id;
        string name;
        uint startPrice;
        string linkImage;
        ProductStatus status;
        address addressWinner;
        uint finalPrice;
        address ownerProduct;
    }

    enum ProductStatus {
        None,
        Done,
        Fail
    }

    enum SessionStatus{
        None,
        Valid,
        Invalid,
        Opened,
        Close
    }
    struct ProductInput{
        string name;
        uint startPrice;
        string linkImage;
    }

    function createSession(string memory name , ProductInput[] memory productInput) public {
        if(rooms[msg.sender].addressUser == address(0x0)){
            rooms[msg.sender].addressUser = msg.sender;
            countRoom++;
        }

        uint countSession = rooms[msg.sender].countSession;
        for(uint i = 0; i < productInput.length; i++)
            rooms[msg.sender].sessions[countSession].products[i] = Product(
                i,
                productInput[i].name, 
                productInput[i].startPrice,
                productInput[i].linkImage,
                ProductStatus.None,
                address(0x0),
                productInput[i].startPrice,
                msg.sender);
        rooms[msg.sender].sessions[countSession].totalProduct = productInput.length;
        rooms[msg.sender].sessions[countSession].status = SessionStatus.None;
        rooms[msg.sender].sessions[countSession].name = name;
        rooms[msg.sender].countSession++;
    }

    function openSession(uint sessionId) public {
        address roomIndex = msg.sender;
        if(rooms[roomIndex].sessions[sessionId].status == SessionStatus.Valid && rooms[roomIndex].sessions[sessionId].status != SessionStatus.Opened){
            rooms[roomIndex].sessions[sessionId].status = SessionStatus.Opened;
            rooms[roomIndex].sessions[sessionId].openTime = block.timestamp;
            sessionsOpen.push(SessionInfo(
                sessionId,
                rooms[roomIndex].sessions[sessionId].name,
                rooms[roomIndex].sessions[sessionId].totalProduct,
                block.timestamp,
                rooms[roomIndex].sessions[sessionId].closeTime,
                rooms[roomIndex].sessions[sessionId].status,
                msg.sender,
                rooms[roomIndex].sessions[sessionId].totalPrice
            ));
            countSessionOpen++;
        }
    }

    function closeSession(uint sessionId, uint index) public {
        address roomIndex = msg.sender;
        if(rooms[roomIndex].sessions[sessionId].status == SessionStatus.Opened){
            rooms[roomIndex].sessions[sessionId].status = SessionStatus.Close;
            rooms[roomIndex].sessions[sessionId].closeTime = block.timestamp;
            delete sessionsOpen[index];
            countSessionOpen--;

            for(uint i = 0; i < rooms[roomIndex].sessions[sessionId].totalProduct; i++){
                if(rooms[roomIndex].sessions[sessionId].products[i].addressWinner != address(0x0)){
                    rooms[roomIndex].sessions[sessionId].totalPrice += rooms[roomIndex].sessions[sessionId].products[i].finalPrice;
                }
            }
            if(rooms[roomIndex].sessions[sessionId].totalPrice > 5 * 1 * (10**18))
                payable(msg.sender).transfer(rooms[roomIndex].sessions[sessionId].totalPrice - (5 * 1 * (10**18)));
        }
    }

    function getSessionInfo(address ownerSession, uint sessionId) public view returns (uint id, uint totalProduct, uint openTime, uint closeTime, SessionStatus status){
        return (
            rooms[ownerSession].sessions[sessionId].id,
            rooms[ownerSession].sessions[sessionId].totalProduct,
            rooms[ownerSession].sessions[sessionId].openTime,
            rooms[ownerSession].sessions[sessionId].closeTime,
            rooms[ownerSession].sessions[sessionId].status);
    }

   function getListSessionOpen() public view returns (SessionInfo[] memory) {
       return sessionsOpen;
   }

    function getMyListSession() public view returns (SessionInfo[] memory) {
        SessionInfo[] memory sessionInfo = new SessionInfo[](rooms[msg.sender].countSession);
        for(uint i = 0; i < rooms[msg.sender].countSession; i++){
            sessionInfo[i] = SessionInfo(
                i, 
                rooms[msg.sender].sessions[i].name, 
                rooms[msg.sender].sessions[i].totalProduct, 
                rooms[msg.sender].sessions[i].openTime, 
                rooms[msg.sender].sessions[i].closeTime, 
                rooms[msg.sender].sessions[i].status,
                msg.sender,
                rooms[msg.sender].sessions[i].totalPrice
                );
        }
        return sessionInfo;
    }

    function getProductBySession(address ownerSession, uint sessionId) public view returns (Product[] memory) {
        Product[] memory products = new Product[](rooms[ownerSession].sessions[sessionId].totalProduct);
        for(uint i = 0; i < rooms[ownerSession].sessions[sessionId].totalProduct; i++){
            products[i] = rooms[ownerSession].sessions[sessionId].products[i];
        }
        return products;
    }

    function upPriceProduct(address ownerProduct, uint sessionId, uint productId, uint price) external payable {
                
        if(rooms[ownerProduct].sessions[sessionId].products[productId].addressWinner != address(0x0)){
            payable(rooms[ownerProduct].sessions[sessionId].products[productId].addressWinner).transfer(rooms[ownerProduct].sessions[sessionId].products[productId].finalPrice);
        }

        rooms[ownerProduct].sessions[sessionId].products[productId].finalPrice = price;
        rooms[ownerProduct].sessions[sessionId].products[productId].addressWinner = msg.sender;
    }

    function confirmSession(address ownerSession, uint sessionId, bool isAccept, string memory secretInput) public {
        if(bytes(secretInput).length != bytes(secret).length && keccak256(abi.encodePacked(secretInput)) != keccak256(abi.encodePacked(secret))) return;
        if(rooms[ownerSession].sessions[sessionId].status != SessionStatus.None) return;
        
        if(isAccept){
            rooms[ownerSession].sessions[sessionId].status = SessionStatus.Valid;
        }else{
            rooms[ownerSession].sessions[sessionId].status = SessionStatus.Invalid;
        }
    }
}