// NOTE:
// This package is a temporary compatibility shim for a known issue
// between TCA's @Reducer enum macro and Swift 6.2's MainActor default
// isolation.
//
// Remove this package once the upstream TCA issue is resolved.

import ComposableArchitecture

@attached(
  member,
  names:
    named(State),
  named(Action),
  named(init),
  named(body),
  named(CaseScope),
  named(scope)
)
@attached(memberAttribute)
@attached(extension, conformances: Reducer, CaseReducer)
public macro MainActorReducer() = #externalMacro(module: "TCACompatibilityMacros", type: "MainActorReducerMacro")
