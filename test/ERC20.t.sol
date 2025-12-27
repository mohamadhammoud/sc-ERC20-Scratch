// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "src/ERC20.sol";

contract ERC20Test is Test {
    ERC20 public token;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    string public constant TOKEN_NAME = "Test Token";
    string public constant TOKEN_SYMBOL = "TEST";
    uint8 public constant TOKEN_DECIMALS = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        token = new ERC20(TOKEN_NAME, TOKEN_SYMBOL);
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsName() public view {
        assertEq(token.name(), TOKEN_NAME);
    }

    function test_Constructor_SetsSymbol() public view {
        assertEq(token.symbol(), TOKEN_SYMBOL);
    }

    function test_Constructor_SetsDecimals() public view {
        assertEq(token.decimals(), TOKEN_DECIMALS);
    }

    // ============ Initial State Tests ============

    function test_InitialTotalSupply_IsZero() public view {
        assertEq(token.totalSupply(), 0);
    }

    function test_InitialBalance_IsZero() public view {
        assertEq(token.balanceOf(alice), 0);
    }

    function test_InitialAllowance_IsZero() public view {
        assertEq(token.allowance(alice, bob), 0);
    }

    // ============ Mint Tests ============

    function test_Mint_IncreasesTotalSupply() public {
        uint256 amount = 1000;
        token.mint(alice, amount);
        assertEq(token.totalSupply(), amount);
    }

    function test_Mint_IncreasesBalance() public {
        uint256 amount = 1000;
        token.mint(alice, amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_Mint_EmitsTransfer() public {
        uint256 amount = 1000;
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, amount);
        token.mint(alice, amount);
    }

    function test_Mint_ReturnsTrue() public {
        assertTrue(token.mint(alice, 1000));
    }

    function test_Mint_MultipleTimes_Accumulates() public {
        token.mint(alice, 1000);
        token.mint(alice, 500);
        assertEq(token.balanceOf(alice), 1500);
        assertEq(token.totalSupply(), 1500);
    }

    function test_Mint_RevertsWhen_ToIsZero() public {
        vm.expectRevert("ERC20: Invalid recipient");
        token.mint(address(0), 1000);
    }

    // ============ Transfer Tests ============

    function test_Transfer_Success() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        bool success = token.transfer(bob, amount);

        assertTrue(success);
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), amount);
    }

    function test_Transfer_EmitsTransfer() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, amount);
        token.transfer(bob, amount);
    }

    function test_Transfer_ReturnsTrue() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        assertTrue(token.transfer(bob, 1000));
    }

    function test_Transfer_PartialAmount() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 300;
        token.mint(alice, mintAmount);

        vm.prank(alice);
        token.transfer(bob, transferAmount);

        assertEq(token.balanceOf(alice), mintAmount - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
    }

    function test_Transfer_RevertsWhen_InsufficientBalance() public {
        token.mint(alice, 500);

        vm.prank(alice);
        vm.expectRevert("ERC20: insufficient balance");
        token.transfer(bob, 1000);
    }

    function test_Transfer_RevertsWhen_ToIsZero() public {
        token.mint(alice, 1000);

        vm.prank(alice);
        vm.expectRevert("ERC20: Invalid recipient");
        token.transfer(address(0), 1000);
    }

    // ============ Approve Tests ============

    function test_Approve_SetsAllowance() public {
        uint256 amount = 1000;
        vm.prank(alice);
        token.approve(bob, amount);

        assertEq(token.allowance(alice, bob), amount);
    }

    function test_Approve_EmitsApproval() public {
        uint256 amount = 1000;
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, bob, amount);
        token.approve(bob, amount);
    }

    function test_Approve_ReturnsTrue() public {
        vm.prank(alice);
        assertTrue(token.approve(bob, 1000));
    }

    function test_Approve_CanUpdateAllowance() public {
        vm.prank(alice);
        token.approve(bob, 1000);
        assertEq(token.allowance(alice, bob), 1000);

        vm.prank(alice);
        token.approve(bob, 2000);
        assertEq(token.allowance(alice, bob), 2000);
    }

    function test_Approve_CanSetToZero() public {
        vm.prank(alice);
        token.approve(bob, 1000);
        assertEq(token.allowance(alice, bob), 1000);

        vm.prank(alice);
        token.approve(bob, 0);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_Approve_RevertsWhen_SpenderIsZero() public {
        vm.prank(alice);
        vm.expectRevert("ERC20: Invalid spender");
        token.approve(address(0), 1000);
    }

    // ============ TransferFrom Tests ============

    function test_TransferFrom_Success() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        bool success = token.transferFrom(alice, charlie, amount);

        assertTrue(success);
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(charlie), amount);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_TransferFrom_DecreasesAllowance() public {
        uint256 approveAmount = 1000;
        uint256 transferAmount = 300;
        token.mint(alice, approveAmount);

        vm.prank(alice);
        token.approve(bob, approveAmount);

        vm.prank(bob);
        token.transferFrom(alice, charlie, transferAmount);

        assertEq(token.allowance(alice, bob), approveAmount - transferAmount);
    }

    function test_TransferFrom_EmitsTransfer() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, charlie, amount);
        token.transferFrom(alice, charlie, amount);
    }

    function test_TransferFrom_DoesNotEmitApproval_WhenAllowanceDecreases()
        public
    {
        uint256 approveAmount = 1000;
        uint256 transferAmount = 300;
        token.mint(alice, approveAmount);

        vm.prank(alice);
        token.approve(bob, approveAmount);

        // transferFrom does NOT emit Approval event when decreasing allowance
        // Only the approve() function emits Approval events
        vm.prank(bob);
        token.transferFrom(alice, charlie, transferAmount);

        // Verify allowance was decreased but no Approval event was emitted
        assertEq(token.allowance(alice, bob), approveAmount - transferAmount);
    }

    function test_TransferFrom_ReturnsTrue() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        token.approve(bob, 1000);

        vm.prank(bob);
        assertTrue(token.transferFrom(alice, charlie, 1000));
    }

    function test_TransferFrom_WithMaxAllowance_DoesNotDecrease() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(alice, charlie, amount);

        assertEq(token.allowance(alice, bob), type(uint256).max);
    }

    function test_TransferFrom_ExactAllowance_BecomesZero() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        token.approve(bob, amount);

        // Transfer exact allowance amount, should become 0
        vm.prank(bob);
        token.transferFrom(alice, charlie, amount);

        assertEq(token.allowance(alice, bob), 0);
        assertEq(token.balanceOf(charlie), amount);
    }

    function test_TransferFrom_ZeroAmount() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        token.approve(bob, 1000);

        vm.prank(bob);
        bool success = token.transferFrom(alice, charlie, 0);

        assertTrue(success);
        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.balanceOf(charlie), 0);
        assertEq(token.allowance(alice, bob), 1000); // Allowance unchanged for zero amount
    }

    function test_TransferFrom_MultipleTransfers_WithMaxAllowance() public {
        token.mint(alice, 5000);

        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(alice, charlie, 1000);

        vm.prank(bob);
        token.transferFrom(alice, charlie, 2000);

        assertEq(token.allowance(alice, bob), type(uint256).max);
        assertEq(token.balanceOf(charlie), 3000);
    }

    function test_TransferFrom_RevertsWhen_FromIsZero() public {
        vm.prank(alice);
        token.approve(bob, 1000);

        vm.prank(bob);
        vm.expectRevert("ERC20: Invalid sender");
        token.transferFrom(address(0), charlie, 1000);
    }

    function test_TransferFrom_RevertsWhen_ToIsZero() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        token.approve(bob, 1000);

        vm.prank(bob);
        vm.expectRevert("ERC20: Invalid recipient");
        token.transferFrom(alice, address(0), 1000);
    }

    function test_TransferFrom_RevertsWhen_InsufficientAllowance() public {
        token.mint(alice, 1000);
        vm.prank(alice);
        token.approve(bob, 500);

        vm.prank(bob);
        vm.expectRevert("ERC20: insufficient allowance");
        token.transferFrom(alice, charlie, 1000);
    }

    function test_TransferFrom_RevertsWhen_InsufficientBalance() public {
        token.mint(alice, 500);
        vm.prank(alice);
        token.approve(bob, 1000);

        vm.prank(bob);
        vm.expectRevert("ERC20: insufficient balance");
        token.transferFrom(alice, charlie, 1000);
    }

    // ============ Edge Cases ============

    function test_Transfer_ZeroAmount() public {
        token.mint(alice, 1000);

        vm.prank(alice);
        bool success = token.transfer(bob, 0);

        assertTrue(success);
        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_Transfer_ToSelf() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
    }

    function test_TransferFrom_ToSelf() public {
        uint256 amount = 1000;
        token.mint(alice, amount);

        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        token.transferFrom(alice, alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_Approve_ToSelf() public {
        vm.prank(alice);
        token.approve(alice, 1000);
        assertEq(token.allowance(alice, alice), 1000);
    }

    function test_MultipleTransfers() public {
        token.mint(alice, 3000);

        vm.prank(alice);
        token.transfer(bob, 1000);

        vm.prank(alice);
        token.transfer(charlie, 1000);

        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.balanceOf(bob), 1000);
        assertEq(token.balanceOf(charlie), 1000);
    }

    function test_MultipleTransferFrom() public {
        token.mint(alice, 3000);
        vm.prank(alice);
        token.approve(bob, 3000);

        vm.prank(bob);
        token.transferFrom(alice, charlie, 1000);

        vm.prank(bob);
        token.transferFrom(alice, charlie, 1000);

        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.balanceOf(charlie), 2000);
        assertEq(token.allowance(alice, bob), 1000);
    }

    // ============ Integration Tests ============

    function test_FullWorkflow() public {
        // Mint tokens to alice
        token.mint(alice, 1000);
        assertEq(token.balanceOf(alice), 1000);

        // Alice approves bob
        vm.prank(alice);
        token.approve(bob, 500);
        assertEq(token.allowance(alice, bob), 500);

        // Bob transfers from alice to charlie
        vm.prank(bob);
        token.transferFrom(alice, charlie, 300);
        assertEq(token.balanceOf(alice), 700);
        assertEq(token.balanceOf(charlie), 300);
        assertEq(token.allowance(alice, bob), 200);

        // Alice transfers directly to charlie
        vm.prank(alice);
        token.transfer(charlie, 200);
        assertEq(token.balanceOf(alice), 500);
        assertEq(token.balanceOf(charlie), 500);
    }
}
