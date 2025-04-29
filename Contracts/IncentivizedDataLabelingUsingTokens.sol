// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract DataLabelingIncentives is Ownable, Pausable, Initializable {
    struct Label {
        string value;
        address submitter;
        uint256 timestamp;
        uint8 upvotes;
        uint8 downvotes;
    }

    mapping(address => uint256) public tokenBalance;
    mapping(uint256 => Label[]) public labeledData;
    mapping(address => uint256) public userLevel;
    mapping(address => uint256) public labelsSubmitted;
    mapping(address => int256) public userReputation;
    mapping(address => bool) public moderators;

    uint256 public totalSupply;
    uint256 public rewardRate;
    uint256 public submissionFee;

    event DataLabeled(address indexed user, uint256 indexed dataId, string label, uint256 reward);
    event RewardWithdrawn(address indexed user, uint256 amount);
    event LabelUpdated(uint256 indexed dataId, uint256 indexed labelIndex, string newLabel);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event SubmissionFeeUpdated(uint256 newFee);
    event UserLevelUpdated(address indexed user, uint256 newLevel);
    event ReputationUpdated(address indexed user, int256 reputation);
    event ModeratorAdded(address indexed moderator);
    event ModeratorRemoved(address indexed moderator);

    modifier onlyModerator() {
        require(moderators[msg.sender], "Not a moderator");
        _;
    }

    function initialize(uint256 _rewardRate, uint256 _submissionFee) external initializer {
        rewardRate = _rewardRate;
        submissionFee = _submissionFee;
        _transferOwnership(msg.sender);
    }

    function submitLabel(uint256 dataId, string memory label) public whenNotPaused {
        require(tokenBalance[msg.sender] >= submissionFee, "Insufficient balance");
        tokenBalance[msg.sender] -= submissionFee;
        labeledData[dataId].push(Label(label, msg.sender, block.timestamp, 0, 0));
        tokenBalance[msg.sender] += rewardRate;
        labelsSubmitted[msg.sender]++;
        _updateUserLevel(msg.sender);
        emit DataLabeled(msg.sender, dataId, label, rewardRate);
    }

    function voteOnLabel(uint256 dataId, uint256 labelIndex, bool upvote) external whenNotPaused {
        Label storage label = labeledData[dataId][labelIndex];
        if (upvote) {
            label.upvotes++;
            userReputation[label.submitter]++;
        } else {
            label.downvotes++;
            userReputation[label.submitter]--;
        }
        emit ReputationUpdated(label.submitter, userReputation[label.submitter]);
    }

    function updateLabel(uint256 dataId, uint256 labelIndex, string memory newLabel) public onlyModerator {
        labeledData[dataId][labelIndex].value = newLabel;
        emit LabelUpdated(dataId, labelIndex, newLabel);
    }

    function transferTokens(address to, uint256 amount) public whenNotPaused {
        require(tokenBalance[msg.sender] >= amount, "Insufficient balance");
        tokenBalance[msg.sender] -= amount;
        tokenBalance[to] += amount;
        emit TokensTransferred(msg.sender, to, amount);
    }

    function withdrawRewards() public whenNotPaused {
        uint256 amount = tokenBalance[msg.sender];
        require(amount > 0, "No rewards to withdraw");
        tokenBalance[msg.sender] = 0;
        emit RewardWithdrawn(msg.sender, amount);
    }

    function mintTokens(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        tokenBalance[to] += amount;
        totalSupply += amount;
        emit TokensMinted(to, amount);
    }

    function burnTokens(uint256 amount) public whenNotPaused {
        require(tokenBalance[msg.sender] >= amount, "Insufficient balance");
        tokenBalance[msg.sender] -= amount;
        totalSupply -= amount;
        emit TokensBurned(msg.sender, amount);
    }

    function updateRewardRate(uint256 newRate) public onlyOwner {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    function updateSubmissionFee(uint256 newFee) public onlyOwner {
        submissionFee = newFee;
        emit SubmissionFeeUpdated(newFee);
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function addModerator(address mod) public onlyOwner {
        moderators[mod] = true;
        emit ModeratorAdded(mod);
    }

    function removeModerator(address mod) public onlyOwner {
        moderators[mod] = false;
        emit ModeratorRemoved(mod);
    }

    function _updateUserLevel(address user) internal {
        uint256 newLevel = labelsSubmitted[user] / 10;
        userLevel[user] = newLevel;
        emit UserLevelUpdated(user, newLevel);
    }

    function getLabel(uint256 dataId, uint256 labelIndex) public view returns (Label memory) {
        return labeledData[dataId][labelIndex];
    }

    function getBalance(address user) public view returns (uint256) {
        return tokenBalance[user];
    }
}
