// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {PoolPay} from "./PoolPay.sol";

contract PoolPayFactory {
    address[] public deployedPools;
    mapping(address => address[]) public userCreatedPools;
    mapping(address => address[]) public JoinedPools;


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
        string memory _referralCode, 
        string memory _poolName
    ) public returns(address) {
        PoolPay newPool = new PoolPay(
            _targetAmount,
            _minimumAmount,
            msg.sender,
            _referralCode,
            _poolName
        );
        deployedPools.push(address(newPool));
        userCreatedPools[msg.sender].push(address(newPool));


        emit PoolCreated(
            address(newPool),
            msg.sender,
            _targetAmount,
            _minimumAmount,
            _referralCode
        );
        return address(newPool);
    }

    function joinPool(address poolAddress, string memory _referralCode) public {
        PoolPay pool = PoolPay(poolAddress);
        pool.joinGroup(_referralCode);
        JoinedPools[msg.sender].push(poolAddress);
        userCreatedPools[msg.sender].push(poolAddress);
       
    }

    function getDeployedPools() public view returns (address[] memory) {
        return deployedPools;
    }

    function getUserPools(address user) public view returns (address[] memory) {
        return userCreatedPools[user];
    }
}
