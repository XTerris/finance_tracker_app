# Interface Components Class Diagram

## Overview

This document contains a UML class diagram for all **interface (UI) components** in the Finance Tracker application. The diagram follows the same style and structure as the domain diagram, with improvements for reduced whitespace and cleaner layout.

## File Location

- **Diagram File**: `INTERFACE_DIAGRAM.puml`
- **Format**: PlantUML

## How to View

You can view this PlantUML diagram using:

1. **Online PlantUML Editor**: 
   - Visit https://www.plantuml.com/plantuml/uml/
   - Copy the contents of `INTERFACE_DIAGRAM.puml` and paste it into the editor

2. **VS Code Extension**:
   - Install "PlantUML" extension
   - Open `INTERFACE_DIAGRAM.puml`
   - Press `Alt+D` to preview

3. **Command Line**:
   ```bash
   plantuml INTERFACE_DIAGRAM.puml
   ```

## Diagram Structure

The diagram is organized into the following layers (top to bottom):

### 1. Application Root
- `App` - Main application widget
- `HomePage` - Root page with tab navigation
- `NavigationBar` - Bottom navigation bar component
- `NoThumbScrollBehavior` - Custom scroll behavior

### 2. Tab Screens (Main Views)
- `DashboardTab` - Overview screen with statistics and recent transactions
- `HistoryTab` - Full transaction history with add functionality
- `GoalsTab` - Account management and savings goals
- `ReportsTab` - Reports and analytics screen

### 3. Display Components (Plates)
- `TransactionPlate` - Displays individual transaction information
- `AccountPlate` - Displays account information with goals

### 4. Bottom Sheets (Forms)

**Add Forms:**
- `AddTransactionBottomSheet` - Form to create new transactions
- `AddAccountBottomSheet` - Form to create new accounts
- `AddGoalBottomSheet` - Form to create new savings goals

**Edit Forms:**
- `EditTransactionBottomSheet` - Form to edit transactions
- `EditAccountBottomSheet` - Form to edit accounts
- `EditGoalBottomSheet` - Form to edit goals

### 5. Providers (State Management)
- `UserProvider` - Manages user state
- `AccountProvider` - Manages accounts state
- `TransactionProvider` - Manages transactions state
- `CategoryProvider` - Manages categories state
- `GoalProvider` - Manages goals state

All providers extend `ChangeNotifier` from the Flutter Provider package.

### 6. Helper Classes & Enums
- `_DashboardStats` - Helper class for dashboard calculations
- `TransactionType` - Enum for transaction types (expense, income, transfer)

## Relationship Types

The diagram uses the following UML relationship notations:

- `*--` **Composition**: Strong ownership (e.g., HomePage contains tabs)
- `-->` **Association**: Direct usage (e.g., tabs display components)
- `..>` **Dependency**: Uses or depends on (e.g., widgets use providers)
- `--` **Simple Association**: General relationship (e.g., with enums)
- `-[hidden]-` **Hidden relationships**: Layout anchors to improve diagram layout

## Key Design Patterns

### 1. Provider Pattern (State Management)
All major tabs and components depend on Provider classes for state management. This follows Flutter's recommended approach for state management.

### 2. Widget Composition
The application is built using Flutter's compositional widget architecture:
- `App` → `HomePage` → Tabs → Components → Forms

### 3. Form Separation
Add and Edit operations are separated into distinct bottom sheet components for better maintainability.

### 4. Display Components (Plates)
Reusable display components (`TransactionPlate`, `AccountPlate`) encapsulate presentation logic.

## Styling Features

The diagram includes the following styling improvements:

- **Orthogonal lines** (`linetype ortho`) - Clean perpendicular connections
- **Reduced spacing** (`ranksep 45`, `nodesep 32`) - Compact layout
- **No shadows** - Cleaner appearance
- **Hidden layout anchors** - Guides PlantUML to reduce whitespace and crossing lines
- **Stereotypes** - Widget types are clearly marked (StatelessWidget, StatefulWidget, ChangeNotifier)

## Notes

- All methods starting with `_` are private
- Public methods use `+` prefix, private use `-` prefix
- The diagram focuses on structure and relationships, not implementation details
- Some complex implementation details are simplified for clarity
- The diagram represents the current state of the interface layer as of the last update

## Related Diagrams

- **Domain Diagram**: See the domain layer class diagram for business logic and data access components
