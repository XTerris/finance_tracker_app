# AddBottomSheetBase Refactoring

## Overview
This refactoring introduces a common base class `AddBottomSheetBase` for all bottom sheet widgets in the finance tracker app, eliminating code duplication and providing a consistent structure.

## Changes Made

### New Base Class
Created `lib/widgets/tabs/tab_widgets/add_bottom_sheet_base.dart` with:
- `AddBottomSheetBase` - Abstract widget class
- `AddBottomSheetBaseState<T>` - Abstract state class with common functionality

### Common Functionality Extracted
The base class provides:
1. **Form structure** - GlobalKey<FormState> managed internally as `formKey`
2. **Loading state** - `isLoading` boolean and `setLoading(bool)` method
3. **Standard UI layout**:
   - Container with padding (including keyboard inset handling)
   - SingleChildScrollView wrapper
   - Header row with title and close button
   - Form content area (customizable via `buildFormContent()`)
   - Submit button with loading indicator
4. **Error handling** - `showSnackBar()` utility method
5. **Form submission** - `handleSubmit()` wrapper with validation and loading state

### Abstract Methods to Override
Subclasses must implement:
- `String get title` - The bottom sheet title
- `String get submitButtonText` - The submit button label
- `Widget buildFormContent(BuildContext context)` - The form fields
- `Future<void> submitForm()` - The submission logic

### Refactored Bottom Sheets
All 6 bottom sheets now extend the base class:
1. **AddTransactionBottomSheet** - Complex form with dynamic fields based on transaction type
2. **AddAccountBottomSheet** - Simple form with name and balance
3. **AddGoalBottomSheet** - Form with target amount and date picker (custom header layout)
4. **EditTransactionBottomSheet** - Similar to Add with existing data
5. **EditAccountBottomSheet** - Simple edit form
6. **EditGoalBottomSheet** - Edit form with date picker

### Special Cases Handled
- **AddGoalBottomSheet** overrides `build()` to provide custom header layout showing account name
- **Transaction bottom sheets** have custom validation logic before form submission
- All sheets preserve their original functionality and parameters

## Benefits
1. **Code Reduction**: ~188 lines of duplicate code eliminated
2. **Consistency**: All bottom sheets have the same look and feel
3. **Maintainability**: Changes to common behavior only need to be made in one place
4. **Type Safety**: Generic state class ensures type-safe widget access
5. **Testability**: Base class can be tested independently with test implementations

## Testing
- Added comprehensive test suite in `test/add_bottom_sheet_base_test.dart`
- Tests cover: rendering, validation, loading states, form submission, and user interactions
- All existing functionality preserved - no breaking changes to public API

## Code Statistics
- **Before**: ~594 lines across 6 files
- **After**: ~406 lines across 6 files + 131 lines in base class
- **Net change**: -57 lines of code
- **Duplicate code eliminated**: ~188 lines
