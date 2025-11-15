// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";
import {PoolPayFactory} from "../src/PoolPayFactory.sol";

contract PoolFactoryScript is Script {
    PoolPayFactory public poolFactory;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        poolFactory = new PoolPayFactory();

        vm.stopBroadcast();
    }
}   