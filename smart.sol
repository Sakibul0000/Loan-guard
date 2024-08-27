// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract LoanAgreement {
    address public lender;
    address public borrower;
    uint256 public loanAmount;
    uint256 public interestRate; // Interest rate as a percentage (e.g., 5 means 5%)
    uint256 public loanDuration; // Loan duration in seconds
    uint256 public startTime;
    bool public loanActive;

    event LoanInitialized(address indexed borrower, uint256 loanAmount, uint256 interestRate, uint256 loanDuration);
    event LoanRepaid(address indexed borrower, uint256 repaymentAmount);
    event LoanDefaulted(address indexed borrower);

    modifier onlyLender() {
        require(msg.sender == lender, "Only the lender can call this function");
        _;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "Only the borrower can call this function");
        _;
    }

    modifier loanIsActive() {
        require(loanActive, "Loan is not active");
        _;
    }

    constructor(address _borrower, uint256 _loanAmount, uint256 _interestRate, uint256 _loanDuration) {
        lender = msg.sender;
        borrower = _borrower;
        loanAmount = _loanAmount;
        interestRate = _interestRate;
        loanDuration = _loanDuration;
        loanActive = false;
    }

    // Lender funds the loan
    function fundLoan() external payable onlyLender {
        require(msg.value == loanAmount, "Incorrect loan amount sent");
        require(!loanActive, "Loan is already active");

        // Transfer the loan amount to the borrower
        payable(borrower).transfer(loanAmount);
        startTime = block.timestamp;
        loanActive = true;

        emit LoanInitialized(borrower, loanAmount, interestRate, loanDuration);
    }

    // Borrower repays the loan with interest
    function repayLoan() external payable onlyBorrower loanIsActive {
        uint256 repaymentAmount = calculateRepaymentAmount();
        require(msg.value == repaymentAmount, "Incorrect repayment amount");

        // Transfer the repayment amount to the lender
        payable(lender).transfer(repaymentAmount);

        loanActive = false;

        emit LoanRepaid(borrower, repaymentAmount);
    }

    // Calculate the total repayment amount with interest
    function calculateRepaymentAmount() public view returns (uint256) {
        uint256 interest = (loanAmount * interestRate) / 100;
        return loanAmount + interest;
    }

    // Check if the loan has defaulted
    function checkDefault() external onlyLender loanIsActive {
        if (block.timestamp > startTime + loanDuration) {
            loanActive = false;
            emit LoanDefaulted(borrower);
        }
    }
}
