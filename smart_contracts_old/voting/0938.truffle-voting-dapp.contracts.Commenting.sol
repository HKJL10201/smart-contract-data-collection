pragma solidity ^0.5.0;


contract Commenting {

    // 留言板贴文结构
    struct Post {
        string title;     // 留言内容：题目
        uint commentCountPos;  // 赞数
        uint commentCountNeg;  // 踩数
        mapping (address => loginUser) loginUsers;   // 用户列表
        address[] loginUsersAddress;   // 所有参与评价者的地址
    }
    // user结构
    struct loginUser {
        uint value;   //评论态度
        bool commentd; // 是否评论过
    }

    Post[] public posts;  // 留言数组

    event CreatedPostEvent();   // 创建新留言的事件
    event CreatedCommentEvent();  // 评论事件

    // 获取当前留言个数
    function getNumPosts() public view returns (uint) {
        return posts.length;
    }
    // 获取留言详细信息
    function getPost(uint postInt) public view returns (uint, string memory, uint, uint, uint, address[] memory, bool) {
        if (posts.length > 0) {
            Post storage p = posts[postInt]; // Get the post
            // 返回的数据包括: 留言序号，留言内容，留言赞数，留言踩数，留言互动参与者列表，当前用户评论了没有
            return (postInt, p.title, p.commentCountPos, p.commentCountNeg, 0, p.loginUsersAddress, p.loginUsers[msg.sender].commentd);
        }
    }
    // 添加留言
    function addPost(string memory title) public returns (bool) {
        Post memory post;
        emit CreatedPostEvent(); //触发事件
        post.title = title; // 内容
        posts.push(post);  // 压入数组
        return true;
    }
    // 添加评论
    function comment(uint postInt, uint commentValue) public returns (bool) {
        if (posts[postInt].loginUsers[msg.sender].commentd == false) { // 只有没评论过的才允许评论
            require(commentValue == 1 || commentValue == 2 || commentValue == 3); //获取commentValue(评论态度)
            Post storage p = posts[postInt]; // 获取列表
            if (commentValue == 1) {
                p.commentCountPos += 1;   // 如果是赞同
            } else if (commentValue == 2) {
                p.commentCountNeg += 1; //如果是反对
            }
            p.loginUsers[msg.sender].value = commentValue;
            p.loginUsers[msg.sender].commentd = true;   // 评论过的flag置为true
            p.loginUsersAddress.push(msg.sender); // 当前用户作为参与者压入栈中
            emit CreatedCommentEvent(); //触发事件
            return true;
        } else {
            return false;
        }
    }

}
