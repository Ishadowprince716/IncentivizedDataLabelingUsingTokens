// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataLabelingIncentives {
    address public owner;
    mapping(address => uint256) public tokenBalance;
    mapping(uint256 => string) public labeledData;
    mapping(address => uint256) public userLevel;
    mapping(address => uint256) public labelsSubmitted;
    uint256 public totalSupply;
    uint256 public rewardRate = 10; // Default reward rate
    uint256 public submissionFee = 1; // Fee for submitting a label
    bool public paused = false;

    event DataLabeled(address indexed user, uint256 indexed dataId, string label, uint256 reward);
    event RewardWithdrawn(address indexed user, uint256 amount);
    event LabelUpdated(uint256 indexed dataId, string newLabel);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event SubmissionFeeUpdated(uint256 newFee);
    event ContractPaused();
    event ContractUnpaused();
    event UserLevelUpdated(address indexed user, uint256 newLevel);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // Function to reward users for labeling data
    function submitLabel(uint256 dataId, string memory label) public whenNotPaused {
        require(tokenBalance[msg.sender] >= submissionFee, "Insufficient balance to pay submission fee");
        
        // Deduct submission fee and update labeled data
        tokenBalance[msg.sender] -= submissionFee; 
        labeledData[dataId] = label;

        // Reward users based on the reward rate
        tokenBalance[msg.sender] += rewardRate; 
        labelsSubmitted[msg.sender] += 1; // Increment labels submitted
        updateUser Level(msg.sender); // Update user level

        emit DataLabeled(msg.sender, dataId, label, rewardRate);
    }

    // Function to check the token balance
    function getBalance(address user) public view returns (uint256) {
        return tokenBalance[user];
    }

    // Admin can reset a user's balance
    function resetBalance(address user) public onlyOwner {
        tokenBalance[user] = 0;
    }

    // View label of a specific dataId
    function getLabel(uint256 dataId) public view returns (string memory) {
        return labeledData[dataId];
    }

    // Owner can update a submitted label
    function updateLabel(uint256 dataId, string memory newLabel) public onlyOwner {
        labeledData[dataId] = newLabel;
        emit LabelUpdated(dataId, newLabel);
    }

    // Transfer earned tokens to another user
    function transferTokens(address to, uint256 amount) public whenNotPaused {
        require(tokenBalance[msg.sender] >= amount, "Insufficient balance");
        tokenBalance[msg.sender] -= amount;
        tokenBalance[to] += amount;
        emit TokensTransferred(msg.sender, to, amount);
    }

    // Withdraw rewards
    function withdrawRewards() public whenNotPaused {
        uint256 amount = tokenBalance[msg.sender];
        require(amount > 0, "No rewards to withdraw");
        tokenBalance[msg.sender] = 0; // Reset balance before transferring to prevent reentrancy
        emit RewardWithdrawn(msg.sender, amount);
    }

    // Mint new tokens
    function mintTokens(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to the zero address");
        tokenBalance[to] += amount;
        totalSupply += amount;
        emit TokensMinted(to, amount);
    }

    // Burn tokens
    function burnTokens(uint256 amount) public whenNotPaused {
        require(tokenBalance[msg.sender] >= amount, "Insufficient balance to burn");
        tokenBalance[msg.sender] -= amount;
        totalSupply -= amount;
        emit TokensBurned(msg.sender, amount);
    }

    // Update reward rate
    function updateRewardRate(uint256 newRate) public onlyOwner {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    // Update submission fee
    function updateSubmissionFee(uint256 newFee) public onlyOwner {
        submissionFee = newFee;
        emit SubmissionFeeUpdated(newFee);
    }

    // Pause contract
    function pauseContract() public onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    // Unpause contract
   
