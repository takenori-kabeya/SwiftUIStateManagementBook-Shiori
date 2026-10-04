// Derived from ReducerMacro.swift in
// pointfreeco/swift-composable-architecture 1.26.1.
// Licensed under the MIT License.

import SwiftSyntax

extension DeclGroupSyntax {
  var isEnum: Bool {
    return self.is(EnumDeclSyntax.self)
  }
}

extension AttributedTypeSyntax {
  var isInout: Bool {
    #if canImport(SwiftSyntax600)
      self.specifiers.contains(
        where: { $0.as(SimpleTypeSpecifierSyntax.self)?.specifier.tokenKind == .keyword(.inout) }
      ) == true
    #else
      self.specifier?.tokenKind == .keyword(.inout)
    #endif
  }
}
