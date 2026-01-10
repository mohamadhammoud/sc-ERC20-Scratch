// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {FeeOnTransferToken} from "src/FeeOnTransferToken.sol";
import {BuggyVault} from "src/BuggyVault.sol";

import {IERC20} from "openzeppelin-contracts-5.0.0/contracts/token/ERC20/IERC20.sol";

contract FeeOnTransfer_BuggyVault_Test is Test {
    FeeOnTransferToken token;
    BuggyVault vault;

    address feeCollector = address(0xFEE);
    address alice = address(0xA11CE);

    function setUp() public {
        token = new FeeOnTransferToken(feeCollector);
        vault = new BuggyVault(IERC20(address(token)));

        token.mint(alice, 1000 ether);
    }

    function test_DepositCreditsMoreThanReceived() public {
        // Alice approves vault
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        // Alice deposits 100
        vm.prank(alice);
        vault.deposit(100 ether);

        // ✅ Vault credits Alice as if it received 100
        assertEq(vault.credits(alice), 100 ether);

        // ❗ But vault actually received only 99 because of fee
        assertEq(token.balanceOf(address(vault)), 99 ether);

        // FeeCollector got 1
        assertEq(token.balanceOf(feeCollector), 1 ether);
    }

    function test_WithdrawFailsBecauseVaultDoesNotHaveEnoughTokens() public {
        // Approve + deposit
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.deposit(100 ether);

        // Vault credited 100 but has only 99 -> withdraw 100 will revert
        vm.prank(alice);
        vm.expectRevert("insufficient balance");
        vault.withdraw(100 ether);
    }
}
