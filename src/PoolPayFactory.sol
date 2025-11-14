// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {PoolPay} from "./PoolPay.sol";

contract PoolPayFactory {
    address[] public deployedPools;

    event PoolCreated(
        address poolAddress,
        address creator,
        uint256 targetAmount,
        uint256 minimumAmount,
        string referralCode
    );

    function createPool(
        uint256 _targetAmount,
        uint256 _minimumAmount,
        string memory _referralCode
    ) public {
        PoolPay newPool = new PoolPay(
            _targetAmount,
            _minimumAmount,
            msg.sender,
            _referralCode
        );
        deployedPools.push(address(newPool));

        emit PoolCreated(
            address(newPool),
            msg.sender,
            _targetAmount,
            _minimumAmount,
            _referralCode
        );
    }

    function getDeployedPools() public view returns (address[] memory) {
        return deployedPools;
    }
}
