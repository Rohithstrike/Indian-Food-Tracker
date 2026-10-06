# Architecture

Indian Food Tracker is a native iOS app built with Swift and SwiftUI, using only Apple's own frameworks. Its code is organized in simple layers so every feature has an obvious home.

## Layers

Screens (SwiftUI views)      what the user sees; no calorie math
ViewModels                   prepare data for a screen
Domain logic                 the rules: nutrition math, serving conversion
Repositories + storage       the only code that loads and saves data

This is MVVM with a separate domain layer.

## Folder structure

IndianFoodTracker/
  App/         the app's entry point
  Core/        shared building blocks with no food logic
  Domain/      data shapes and rules
  Data/        storage and repositories
  Features/    one subfolder per area of the app
  Resources/   non-code files

Documentation/ project notes in Markdown

Tests stay in the folders Xcode created.

## Principles

- Screens never calculate nutrition. All calculations live in Domain and are unit tested.
- Only repositories talk to storage.
- Logged meals store a snapshot of their nutrition.
- Custom foods use the same Food shape as built-in foods.
- Nutrition values are never invented. Unknown values stay unknown.

## Deliberately not included yet

- Third-party libraries
- Coordinators, dependency-injection frameworks, and unnecessary protocols
- Any database
- Networking, accounts, analytics, and cloud services
- Services, Migrations, and Utilities folders

## Status

Milestone 3: folder structure created. Folders without files are not yet tracked by Git.
