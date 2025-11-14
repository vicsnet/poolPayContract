// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolPay {
    address public owner;

    address public constant TOKEN_ADDRESS =
        0xD533a949740bb3306d119CC777fa900bA034cd52; // example: CRV token address

    IERC20 token;

    uint256 public constant DECIMAL_FACTOR = 1e18;

    // referral code for the pool
    bytes32 public masterReferralCode;

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

    // pool member
    mapping(address => bool) public isContributor;


    // has contributed in current cycle
    mapping(address poolContributors => mapping(uint256 poolCurrentCycle => bool))
        public hasContributedInCycle;

    // payout position tracking
    mapping(uint256 position => address _contributors) public payoutPosition;

    // paid position tracking
    mapping(uint256 position => bool isPaid) public isPositionPaid;


    //  the target amount and minimum amount will determine the total numuber of user in the group

    constructor(
        uint256 _targetAmount,
        uint256 _minimumAmount,
        address _creator,
        string memory _referralCode
    ) {
        require(_targetAmount > 0 && _minimumAmount > 0, "Invalid amounts");
        token = IERC20(TOKEN_ADDRESS);
        targetAmount = _targetAmount * DECIMAL_FACTOR;
        minimumAmount = _minimumAmount * DECIMAL_FACTOR;
        owner = _creator;

        masterReferralCode = keccak256(abi.encodePacked(_referralCode));
        contributors.push(_creator);
        isContributor[_creator] = true;
        totalContributor = 1;
        currentCycle = 1;
    }

    function getMaxContributors() public view returns (uint256) {
        return targetAmount / minimumAmount;
    }

    // join group
    function joinGroup(string memory _referralCode) external {
        uint256 maxContributors = getMaxContributors();
        require(
            totalContributor <= maxContributors,
            "Max contributors reached"
        );
        bytes32 refferalHash = keccak256(abi.encodePacked(_referralCode));
        require(refferalHash == masterReferralCode, "Invalid referral code");
        require(!isContributor[msg.sender], "Already a contributor");
        contributors.push(msg.sender);
        isContributor[msg.sender] = true;
        totalContributor += 1;
        // for now i am assigning payout position based on join order
        uint256 assignedPayoutPosition = totalContributor + 1;
        payoutPosition[assignedPayoutPosition] = msg.sender;

    }

    // function to contribute into the savings
    function contribute(uint256 _amount) external payable {
        require(currentAmountContributed < targetAmount, "Target already met");
        require(isContributor[msg.sender], "Not a contributor");

        require(
            hasContributedInCycle[msg.sender][currentCycle] == false,
            "Already contributed this cycle"
        );

        require(_amount >= minimumAmount, "Amount less than minimum");
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Insufficient token balance"
        );
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
        payoutPositionTracker += 1;
        address payoutAddress = payoutPosition[payoutPositionTracker];
        require(payoutAddress != address(0), "No payout address found");
        require(
            isPositionPaid[payoutPositionTracker] == false,
            "Position already paid"
        );

        uint256 payoutAmount = currentAmountContributed;
        // reset current amount contributed for next cycle
        currentAmountContributed = 0;
        // mark position as paid
        isPositionPaid[payoutPositionTracker] = true;

        // transfer the payout amount to the payout address
        token.transfer(payoutAddress, payoutAmount);

        // increment cycle
        currentCycle += 1;
    }

    // function to get total contributors
    function getTotalContributors() external view returns (uint256) {
        return totalContributor;    
    }

    // function to get contributors list
    function getContributors() external view returns (address[] memory) {
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
}
