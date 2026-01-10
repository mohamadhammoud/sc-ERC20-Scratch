// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {IERC20Metadata} from "src/interfaces/IERC20Metadata.sol";

contract ERC20 is IERC20Metadata {
    string private _name;
    string private _symbol;
    uint8 private immutable _DECIMALS;

    mapping(address account => uint256 balance) private _balances;
    mapping(address owner => mapping(address spender => uint256 amount)) private _allowances;
    uint256 private _totalSupply;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _DECIMALS = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "ERC20: Invalid spender");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(from != address(0), "ERC20: Invalid sender");
        require(to != address(0), "ERC20: Invalid recipient");

        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        if (currentAllowance != type(uint256).max) {
            _allowances[from][msg.sender] = currentAllowance - amount;
        }

        _transfer(from, to, amount);

        return true;
    }

    function mint(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "ERC20: Invalid recipient");

        _totalSupply += amount;
        _balances[to] += amount;

        emit Transfer(address(0), to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: invalid sender");
        require(to != address(0), "ERC20: Invalid recipient");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: insufficient balance");
        _balances[from] = fromBalance - amount;

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}
