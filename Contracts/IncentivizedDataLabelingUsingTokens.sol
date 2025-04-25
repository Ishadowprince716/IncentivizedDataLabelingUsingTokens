// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataLabelingIncentives {
    address public owner;
    mapping(address => uint256) public tokenBalance;
    mapping(uint256 => string) public labeledData;

    event DataLabeled(address indexed user, uint256 indexed dataId, string label, uint256 reward);
    event RewardWithdrawn(address indexed user, uint256 amount);
    event LabelUpdated(uint256 indexed dataId, string newLabel);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    // Reward users for labeling data
    function submitLabel(uint256 dataId, string memory label) public {
        labeledData[dataId] = label;
        tokenBalance[msg.sender] += 10; // Reward 10 tokens per label
        emit DataLabeled(msg.sender, dataId, label, 10);
    }

    // Get user token balance
    function getBalance(address user) public view returns (uint256) {
        return tokenBalance[user];
    }

    // Admin can reset a user's balance
    function resetBalance(address user) public {
        require(msg.sender == owner, "Only owner can reset balance");
        tokenBalance[user] = 0;
    }

    // View label of a specific dataId
    function getLabel(uint256 dataId) public view returns (string memory) {
        return labeledData[dataId];
    }

    // Owner can update a submitted label
    function updateLabel(uint256 dataId, string memory newLabel) public {
        require(msg.sender == owner, "Only owner can update label");
        labeledData[dataId] = newLabel;
        emit LabelUpdated(dataId, newLabel);
    }

    // Transfer earned tokens to another user
    function transferTokens(address to, uint256 amount) public {
        require(tokenBalance[msg.sender] >= amount, "Insufficient balance");
        tokenBalance[msg.sender] -= amount;
        tokenBalance[to] += amount;
        emit TokensTransferred(msg.sender, to, amount);
    }

    // Simulated withdraw of rewards
    function withdrawRewards() public {
        uint256 amount = tokenBalance[msg.sender];
        require(amount > 0, "No rewards to withdraw");
        tokenBalance[msg.sender] = 0;
        emit RewardWithdrawn(msg.sender, amount);
    }
}


