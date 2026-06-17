# Interconnected and Dynamic Screens with State Management

This plan outlines the refactoring of the DigiPe app to make its screens interconnected and dynamic, using the BLoC pattern and a Repository layer to prepare for backend API integration.

## User Review Required

- **State Management**: Using BLoC for all feature areas.
- **Repository Pattern**: Introducing a repository layer to abstract data fetching.
- **Global Providers**: Key BLoCs will be provided at the top level of the app.

## Proposed Changes

### [Core] [lib/core/repositories](file:///flutter_projects/digi_pe/lib/core/repositories)

Introduce repository classes to handle data logic.

#### [NEW] [base_repository.dart](file:///flutter_projects/digi_pe/lib/core/repositories/base_repository.dart)
- Define a base class or interface for repositories if needed.

#### [NEW] [auth_repository.dart](file:///flutter_projects/digi_pe/lib/core/repositories/auth_repository.dart)
- Handle user login, logout, and profile fetching.

#### [NEW] [orders_repository.dart](file:///flutter_projects/digi_pe/lib/core/repositories/orders_repository.dart)
- Handle fetching orders and placing new orders.

#### [NEW] [product_repository.dart](file:///flutter_projects/digi_pe/lib/core/repositories/product_repository.dart)
- Handle fetching products and variants.

---

### [State Management] [lib/core/bloc](file:///flutter_projects/digi_pe/lib/core/bloc)

Enhance existing BLoCs and create new ones for shared state.

#### [auth_bloc.dart](file:///flutter_projects/digi_pe/lib/core/bloc/auth_bloc.dart)
- Update to include user profile data in `AuthAuthenticated` state.

#### [NEW] [app_bloc_observer.dart](file:///flutter_projects/digi_pe/lib/core/bloc/app_bloc_observer.dart)
- Add a BLoC observer for easier debugging of state changes.

---

### [Features] [lib/features](file:///flutter_projects/digi_pe/lib/features)

Refactor screens to use BLoCs and Repositories.

#### [home_screen.dart](file:///flutter_projects/digi_pe/lib/features/home/presentation/screens/home_screen.dart)
- Use `HomeBloc` to fetch dynamic content (banners, featured products).

#### [product_screen.dart](file:///flutter_projects/digi_pe/lib/features/product/presentation/screens/product_screen.dart)
- Refactor to use `ProductBloc` instead of local `StatefulWidget` state for variant selection.

#### [orders_screen.dart](file:///flutter_projects/digi_pe/lib/features/orders/screens/orders_screen.dart)
- Update `OrdersBloc` to use `OrdersRepository`.

#### [profile_screen.dart](file:///flutter_projects/digi_pe/lib/features/profile/presentation/screens/profile_screen.dart)
- Connect to `AuthBloc` to show real user data.

---

### [Main] [lib/main.dart](file:///flutter_projects/digi_pe/lib/main.dart)

#### [main.dart](file:///flutter_projects/digi_pe/lib/main.dart)
- Wrap `MaterialApp` with `MultiBlocProvider` to provide `AuthBloc`, `OrdersBloc`, and `ProductBloc` globally.

## Verification Plan

### Automated Tests
- Since this is a UI/State refactor, I will focus on manual verification.

### Manual Verification
1.  **Authentication Flow**: Login and verify profile screen and app header update.
2.  **Product Selection**: Change variants in `ProductScreen` and verify price updates.
3.  **Order Placement**: "Purchase" a product and verify it appears in the `OrdersScreen`.
4.  **Data Persistence**: Verify that navigating away and back to a screen preserves/re-fetches state correctly.
