# Balance Management and Transaction History Validation

## Overview

This document describes the enhancements made to the Finance Tracker App to properly manage account balances and validate transaction history.

## Problem Statement

The original implementation had the following issues:

1. **Account balances were not updated**: When adding, editing, or deleting transactions, the related account balances were not automatically updated in the database.

2. **No historical balance validation**: When adding transactions in the past or modifying existing transactions, there was no check to ensure that the account balance never became negative at any point in time.

## Solution

### 1. Automatic Balance Updates

All transaction operations (`createTransaction`, `deleteTransaction`) now automatically update the affected account balances:

- **Expense Transaction** (fromAccountId): Decreases account balance by transaction amount
- **Income Transaction** (toAccountId): Increases account balance by transaction amount  
- **Transfer Transaction**: Decreases fromAccount balance and increases toAccount balance

These updates are performed within database transactions to ensure atomicity - either all changes succeed or all are rolled back.

### 2. Balance History Validation

A new validation algorithm ensures that account balances never go negative at any point in the transaction history:

#### How It Works

When creating or deleting a transaction that affects an account, the system:

1. **Retrieves** all transactions for that account, ordered chronologically
2. **Calculates** the initial balance (before any transactions) by working backwards from the current balance
3. **Simulates** all transactions in chronological order, tracking the balance at each step
4. **Validates** that the balance never drops below zero at any point

If validation fails, the entire operation is rolled back and an error message is returned to the user.

#### Example Scenarios

**Scenario 1: Rejected Transaction**
```
Initial balance: $100
Transaction 1 (now): Expense of $90 → Balance becomes $10
Attempting to add: Transaction 0 (yesterday): Expense of $95

Result: REJECTED
Reason: After Transaction 0, balance would be $5, then after Transaction 1, 
        balance would be -$85 (negative!)
```

**Scenario 2: Accepted Transaction**
```
Initial balance: $1000
Transaction 1 (now): Expense of $100 → Balance becomes $900
Adding: Transaction 0 (yesterday): Expense of $50

Result: ACCEPTED
Reason: After Transaction 0, balance would be $950, then after Transaction 1,
        balance would be $850 (always positive)
Final balance: $850
```

**Scenario 3: Rejected Deletion**
```
Current state:
- Transaction 1 (day 1): Income of $100 → Balance: $100
- Transaction 2 (day 2): Expense of $90 → Balance: $10
Attempting to delete: Transaction 1

Result: REJECTED
Reason: Without Transaction 1, on day 2 the balance would be -$90 (negative!)
```

## Code Changes

### DatabaseService (lib/services/database_service.dart)

1. **createTransaction()**: 
   - Wraps operations in database transaction
   - Updates account balances using `_updateAccountBalance()`
   - Validates balance history using `_validateAccountBalanceHistory()`
   - Throws exception if validation fails

2. **deleteTransaction()**: 
   - Wraps operations in database transaction
   - Reverses the original balance changes
   - Validates that deletion won't cause historical negative balance
   - Throws exception if validation fails

3. **_updateAccountBalance()** (new helper method):
   - Updates account balance atomically using SQL UPDATE

4. **_validateAccountBalanceHistory()** (new helper method):
   - Computes initial balance by reversing all transaction effects
   - Simulates transactions chronologically
   - Returns false if balance ever goes negative

## Testing

Comprehensive test suite added in `test/balance_management_test.dart` covering:

### Basic Balance Updates
- Creating expense transactions updates account balance
- Creating income transactions updates account balance
- Creating transfers updates both account balances
- Deleting transactions reverses balance changes

### Balance History Validation
- Transaction rejected if it would cause negative balance
- Transaction rejected if it would cause historical negative balance
- Transaction accepted if balance stays positive throughout history
- Deletion rejected if it would cause historical negative balance
- Multiple transactions in complex chronological order

## User Impact

### Before
- Account balances were stale and didn't reflect actual transaction history
- Users could create impossible transaction histories (e.g., spending more than available)
- No validation prevented negative balances

### After
- Account balances are automatically updated with every transaction
- Historical transaction additions are validated to ensure consistency
- Users receive clear error messages when attempting invalid operations
- Data integrity is maintained across all transaction operations

## Error Messages

Users will see descriptive error messages when operations fail:

- **Creating invalid transaction**: "Transaction would cause account balance to become negative at some point in history. Transaction rejected."
- **Deleting critical transaction**: "Deleting this transaction would cause account balance to become negative at some point in history. Deletion rejected."

## Performance Considerations

- Balance validation runs in O(n) time where n is the number of transactions for an account
- Validation only runs for accounts affected by the current operation
- Database transactions ensure operations are atomic and isolated
- For typical use cases (hundreds of transactions per account), performance impact is negligible
