//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension TypeSyntax {
  var identifier: String? {
    for token in tokens(viewMode: .all) {
      switch token.tokenKind {
      case .identifier(let identifier):
        return identifier
      default:
        break
      }
    }
    return nil
  }

//  func genericSubstitution(_ parameters: GenericParameterListSyntax?) -> String? {
//    var genericParameters = [String: TypeSyntax?]()
//    if let parameters {
//      for parameter in parameters {
//        genericParameters[parameter.name.text] = parameter.inheritedType
//      }
//    }
//    var iterator = self.asProtocol((any TypeSyntaxProtocol).self).tokens(viewMode: .sourceAccurate)
//      .makeIterator()
//    guard let base = iterator.next() else {
//      return nil
//    }
//
//    if let genericBase = genericParameters[base.text] {
//      if let text = genericBase?.identifier {
//        return "some " + text
//      } else {
//        return nil
//      }
//    }
//    var substituted = base.text
//
//    while let token = iterator.next() {
//      switch token.tokenKind {
//      case .leftAngle:
//        substituted += "<"
//      case .rightAngle:
//        substituted += ">"
//      case .comma:
//        substituted += ","
//      case .identifier(let identifier):
//        let type: TypeSyntax = "\(raw: identifier)"
//        guard let substituedType = type.genericSubstitution(parameters) else {
//          return nil
//        }
//        substituted += substituedType
//        break
//      default:
//        // ignore?
//        break
//      }
//    }
//
//    return substituted
//  }
}

extension AttributeSyntax {
  var availability: AttributeSyntax? {
    if attributeName.identifier == "available" {
      return self
    } else {
      return nil
    }
  }
}

extension IfConfigClauseSyntax.Elements {
  var availability: IfConfigClauseSyntax.Elements? {
    switch self {
    case .attributes(let attributes):
      if let availability = attributes.availability {
        return .attributes(availability)
      } else {
        return nil
      }
    default:
      return nil
    }
  }
}

extension IfConfigClauseSyntax {
  var availability: IfConfigClauseSyntax? {
    if let availability = elements?.availability {
      return with(\.elements, availability)
    } else {
      return nil
    }
  }

  var clonedAsIf: IfConfigClauseSyntax {
    detached.with(\.poundKeyword, .poundIfToken())
  }
}

extension IfConfigDeclSyntax {
  var availability: IfConfigDeclSyntax? {
    var elements = [IfConfigClauseListSyntax.Element]()
    for clause in clauses {
      if let availability = clause.availability {
        if elements.isEmpty {
          elements.append(availability.clonedAsIf)
        } else {
          elements.append(availability)
        }
      }
    }
    if elements.isEmpty {
      return nil
    } else {
      return with(\.clauses, IfConfigClauseListSyntax(elements))
    }

  }
}

extension AttributeListSyntax.Element {
  var availability: AttributeListSyntax.Element? {
    switch self {
    case .attribute(let attribute):
      if let availability = attribute.availability {
        return .attribute(availability)
      }
    case .ifConfigDecl(let ifConfig):
      if let availability = ifConfig.availability {
        return .ifConfigDecl(availability)
      }
    @unknown default:
      return nil
    }
    return nil
  }
}

extension AttributeListSyntax {
  var availability: AttributeListSyntax? {
    var elements = [AttributeListSyntax.Element]()
    for element in self {
      if let availability = element.availability {
        elements.append(availability)
      }
    }
    if elements.isEmpty {
      return nil
    }
    return AttributeListSyntax(elements)
  }
}
