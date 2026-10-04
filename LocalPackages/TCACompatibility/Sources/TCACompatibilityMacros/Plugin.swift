import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TCACompatibilityPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MainActorReducerMacro.self
    ]
}
