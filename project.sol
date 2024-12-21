// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FAQPlatform {
    
    address public owner;
    IERC20 public rewardToken; // ERC-20 token used for rewards
    
    uint256 public rewardAmount = 100 * 10 ** 18; // Reward in tokens (e.g., 100 tokens)
    
    struct FAQ {
        address author;
        string subject;
        string content;
        uint256 submissionTime;
        bool approved;
    }

    FAQ[] public faqs;
    mapping(uint256 => address) public faqApprovers; // Mapping of FAQ index to approver address
    mapping(address => uint256[]) public userSubmittedFAQs; // Mapping user to their submitted FAQ indices
    
    event FAQSubmitted(address indexed author, uint256 indexed faqId, string subject);
    event FAQApproved(uint256 indexed faqId, address approver);
    event FAQRejected(uint256 indexed faqId, address approver);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier onlyApprovedFAQ(uint256 faqId) {
        require(faqs[faqId].approved, "FAQ has not been approved.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only the admin can approve/reject FAQs.");
        _;
    }

    constructor(address _rewardToken) {
        owner = msg.sender;
        rewardToken = IERC20(_rewardToken); // Initialize the reward token contract
    }

    function submitFAQ(string memory subject, string memory content) public {
        uint256 faqId = faqs.length;
        faqs.push(FAQ({
            author: msg.sender,
            subject: subject,
            content: content,
            submissionTime: block.timestamp,
            approved: false
        }));
        
        userSubmittedFAQs[msg.sender].push(faqId);
        
        emit FAQSubmitted(msg.sender, faqId, subject);
    }

    function approveFAQ(uint256 faqId) public onlyAdmin {
        require(faqId < faqs.length, "FAQ ID does not exist.");
        FAQ storage faq = faqs[faqId];
        require(!faq.approved, "FAQ is already approved.");
        
        faq.approved = true;
        faqApprovers[faqId] = msg.sender;
        
        emit FAQApproved(faqId, msg.sender);
        
        // Reward the author
        rewardAuthor(faq.author);
    }

    function rejectFAQ(uint256 faqId) public onlyAdmin {
        require(faqId < faqs.length, "FAQ ID does not exist.");
        FAQ storage faq = faqs[faqId];
        require(!faq.approved, "FAQ is already approved.");
        
        faq.approved = false;
        faqApprovers[faqId] = msg.sender;
        
        emit FAQRejected(faqId, msg.sender);
    }

    function rewardAuthor(address author) private {
        uint256 balance = rewardToken.balanceOf(address(this));
        require(balance >= rewardAmount, "Not enough balance to reward.");
        
        // Transfer the reward to the author
        rewardToken.transfer(author, rewardAmount);
    }

    function setRewardAmount(uint256 _amount) public onlyOwner {
        rewardAmount = _amount;
    }

    function getFAQCount() public view returns (uint256) {
        return faqs.length;
    }

    function getFAQ(uint256 faqId) public view returns (FAQ memory) {
        require(faqId < faqs.length, "FAQ ID does not exist.");
        return faqs[faqId];
    }

    function getUserSubmittedFAQs(address user) public view returns (uint256[] memory) {
        return userSubmittedFAQs[user];
    }
}
