// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolPay {
    address public owner;

    address public constant TOKEN_ADDRESS =
        0x3600000000000000000000000000000000000000; // example: CRV token address

    IERC20 token;

    uint256 public constant DECIMAL_FACTOR = 1e6;

    // referral code for the pool
    bytes32 public masterReferralCode;

    // pool name set when the
    string public poolName;

    string public referrer;

    // contract is deployed

    // Target Amount is set durring contract deployment
    uint256 public targetAmount;

    // minimum amout to be donated is specified
    uint256 public minimumAmount;

    uint256 public totalContributor;

    address[] public contributors;

    uint256 public currentCycle;

    uint256 public currentAmountContributed;

    uint256 public payoutPositionTracker;

    uint256 public cycleDuration; // seconds per cycle
    uint256 public cycleStartTime; // timestamp of current cycle start

    // pool member
    mapping(address => bool) public isContributor;

    // status of the pool
    enum PoolStatus {
        NotStarted,
        Active,
        Completed
    }
    PoolStatus public poolStatus;

    // has contributed in current cycle
    mapping(address poolContributors => mapping(uint256 poolCurrentCycle => bool))
        public hasContributedInCycle;

    // payout position tracking
    mapping(uint256 position => address _contributors) public payoutPosition;
       mapping(address => uint256) public positionOfContributor;

    // paid position tracking
    mapping(uint256 position => bool isPaid) public isPositionPaid;

    //  the target amount and minimum amount will determine the total numuber of user in the group

    constructor(
        uint256 _targetAmount,
        uint256 _minimumAmount,
        address _creator,
        string memory _referralCode,
        string memory _poolName
    ) {
        require(_targetAmount > 0 && _minimumAmount > 0, "Invalid amounts");
        token = IERC20(TOKEN_ADDRESS);
        targetAmount = _targetAmount * DECIMAL_FACTOR;
        minimumAmount = _minimumAmount * DECIMAL_FACTOR;
        owner = _creator;
        poolName = _poolName;
        referrer = _referralCode;

        masterReferralCode = keccak256(abi.encodePacked(_referralCode));
        contributors.push(_creator);
        isContributor[_creator] = true;
        totalContributor = 1;
        currentCycle = 1;
        poolStatus = PoolStatus.NotStarted;
        payoutPosition[1] = _creator;
        positionOfContributor[_creator] = 1;
    }

    function getMaxContributors() public view returns (uint256) {
        return targetAmount / minimumAmount;
    }

    // start the pool
    function startPool(uint256 _cycleDuration) external {
        require(msg.sender == owner, "Only owner can start the pool");
        require(
            poolStatus == PoolStatus.NotStarted,
            "Pool already started or completed"
        );
        uint256 allContributors = getMaxContributors();

        require(allContributors == totalContributor, "Not enough contributors");
        poolStatus = PoolStatus.Active;
        cycleDuration = _cycleDuration; //e.g 7days for weekly: 7*24*60*60
        cycleStartTime = block.timestamp; //start the first cycle
    }

    // join group
    function joinGroup(string memory _referralCode) external {
        uint256 maxContributors = getMaxContributors();
        address user = tx.origin; 
        require(
            totalContributor <= maxContributors,
            "Max contributors reached"
        );
        bytes32 refferalHash = keccak256(abi.encodePacked(_referralCode));
        require(refferalHash == masterReferralCode, "Invalid referral code");
        require(poolStatus == PoolStatus.NotStarted, "Pool is Active");
        require(!isContributor[user], "Already a contributor");
        contributors.push(user);
        isContributor[user] = true;
        totalContributor += 1;
        // for now i am assigning payout position based on join order
        uint256 assignedPayoutPosition = totalContributor;
        payoutPosition[assignedPayoutPosition] = user;
        positionOfContributor[user] = assignedPayoutPosition;
    }

    // function to contribute into the savings
    function contribute(uint256 _amount) external payable {
        require(poolStatus == PoolStatus.Active, "Pool is not active");
        require(isContributor[msg.sender], "Not a contributor");
        // check if current cycle has ended
        if (
            currentAmountContributed >= targetAmount &&
            block.timestamp >= cycleStartTime + cycleDuration
        ) {
            currentCycle += 1;
            // reset for next cycle

            cycleStartTime = block.timestamp;

            currentAmountContributed = 0;
        }
        // require(currentAmountContributed < targetAmount, "Target already met");

        require(
            hasContributedInCycle[msg.sender][currentCycle] == false,
            "Already contributed this cycle"
        );

        require(_amount >= minimumAmount, "Amount less than minimum");

        token.transferFrom(msg.sender, address(this), _amount);

        hasContributedInCycle[msg.sender][currentCycle] = true;
        currentAmountContributed += _amount;
    }

    // function to withdrawAutomatically when target is met
    function withdrawAutomatically() external {
        require(
            currentAmountContributed >= targetAmount,
            "Target amount not met"
        );

        // find the next payout position
         // find the next payout position
        uint256 nextPos = payoutPositionTracker + 1;
        // payoutPositionTracker += 1;
        address payoutAddress = payoutPosition[nextPos];
        require(payoutAddress != address(0), "No payout address found");
        require(
            isPositionPaid[nextPos] == false,
            "Position already paid"
        );

        uint256 payoutAmount = currentAmountContributed;
        // reset current amount contributed for next cycle
        currentAmountContributed = 0;
        payoutPositionTracker = nextPos;
        // mark position as paid
        isPositionPaid[nextPos] = true;

    cycleStartTime = block.timestamp;

        // increment cycle
        currentCycle += 1;
        // transfer the payout amount to the payout address
        token.transfer(payoutAddress, payoutAmount);

    }

    // function to get total contributors
    function getTotalContributors() external view returns (uint256) {
        return totalContributor;
    }

    // function to get contributors list
    function getContributors() public view returns (address[] memory) {
        return contributors;
    }

    // get current cycle
    function getCurrentCycle() external view returns (uint256) {
        return currentCycle;
    }

    // get current amount contributed
    function getCurrentAmountContributed() external view returns (uint256) {
        return currentAmountContributed;
    }

    //   get pool status
    function getPoolStatus() external view returns (PoolStatus) {
        return poolStatus;
    }

    // get referral code hash
    function getReferralCodeHash() external view returns (string memory) {
        bytes memory _bytes = abi.encodePacked(masterReferralCode);
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 b = uint8(_bytes[i]);
            str[2 * i] = hexChars[b >> 4];
            str[2 * i + 1] = hexChars[b & 0x0f];
        }
        return string(str);
    }

function estimatePayoutFor(address user) external view returns (uint256 estimatedCycle, uint256 estimatedTimestamp) {
    if (!isContributor[user]) return (0, 0);

    uint256 userPosition = positionOfContributor[user];
    if (userPosition == 0) return (0, 0);
    if (userPosition <= payoutPositionTracker) return (0, 0); // already paid

    uint256 payoutsUntil = userPosition - (payoutPositionTracker + 1);
    estimatedCycle = currentCycle + payoutsUntil;
    estimatedTimestamp = cycleStartTime + (payoutsUntil + 1) * cycleDuration;

    return (estimatedCycle, estimatedTimestamp);
}

}
