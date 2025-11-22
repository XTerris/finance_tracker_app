# Finance Tracker App

A standalone Flutter personal finance tracking application with local SQLite database.

## Overview

This is a complete personal finance management application that runs entirely offline with local data storage. Track your transactions, manage multiple accounts, set financial goals, and view detailed reports - all without requiring an internet connection.

## Features

- 💰 **Transaction Management**: Record income and expenses with categories
- 🏦 **Multiple Accounts**: Manage different bank accounts and wallets
- 🎯 **Financial Goals**: Set and track savings goals for your accounts
- 📊 **Reports & Analytics**: View spending patterns and financial summaries
- 💾 **Local Storage**: All data stored securely in local SQLite database

## Technical Stack

- **Framework**: Flutter
- **Database**: SQLite (sqflite package)
- **State Management**: Provider pattern
- **UI**: Material Design with Russian localization

## Architecture

The app follows a clean architecture pattern:

- **Models**: Data classes for Transaction, Category, Account, and Goal
- **Services**: DatabaseService handles all SQL operations
- **Providers**: State management for each entity type
- **Widgets**: Reusable UI components and tab-based navigation

## Database Schema

SQLite database with the following tables:
- `categories` - Transaction categories
- `accounts` - Financial accounts
- `transactions` - Income and expense records
- `goals` - Savings goals linked to accounts

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to launch the app

## Development

This app was originally designed as a client for a backend server but has been transformed into a standalone application. All API and caching layers have been replaced with direct SQLite database operations.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/).
