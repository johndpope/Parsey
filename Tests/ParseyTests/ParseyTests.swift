import XCTest
@testable import Parsey

class ParseyTests: XCTestCase {

    func testIntegers() {
        do {
            try XCTAssertEqual(Lexer.unsignedInteger.map{Int($0)!}.parse("12345"), 12345)
            try XCTAssertEqual(Lexer.signedInteger.map{Int($0)!}.parse("12345"), 12345)
            try XCTAssertEqual(Lexer.signedInteger.map{Int($0)!}.parse("-12345"), -12345)
            try XCTAssertEqual(Lexer.signedInteger.map{Int($0)!}.parse("+12345"), 12345)
        }
    }

    func testSourceRange() throws {
        
        indirect enum Expr : CustomStringConvertible {
            case sExp([Expr], SourceRange)
            case int(Int, SourceRange)
            case id(String, SourceRange)

            var description: String {
                switch self {
                    case let .sExp(exps, range): return "Expr:(\(range)):\(exps)"
                    case let .int(i, range): return "Int:(\(range)):\(i)"
                    case let .id(id, range): return "ID:(\(range)):\(id)"
                }
            }

            var range: SourceRange {
                switch self {
                    case let .sExp(_, range): return range
                    case let .int(_, range): return range
                    case let .id(_, range): return range
                }
            }
        }

        enum Grammar {
            static let anInt = Lexer.signedInteger.mapParse { parse in Expr.int(Int(parse.target)!, parse.range) }
            static let anID = Lexer.regex("[a-zA-Z_+\\-*/][0-9a-zA-Z_+\\-*/]*").mapParse { parse in
                Expr.id(parse.target, parse.range)
            }

            static let aSExp: Parser<Expr> = anExp.many(separatedBy: Lexer.whitespaces)
                .between(Lexer.character("("), Lexer.character(")")).mapParse { parse in
                Expr.sExp(parse.target, parse.range)
            }

            static let anExp = anInt | anID | aSExp
        }

        let _ = try Grammar.anExp.parse("(+ (+ +1 -20) 2 3)")
    }

    func testStrings() {
        do {
            try XCTAssertEqual(Lexer.string("Hello").parse("Hello"), "Hello")
            try XCTAssertEqual(Lexer.regex("(Hello)*").parse("HelloHelloHello"), "HelloHelloHello")
            try XCTAssertEqual((Lexer.whitespaces ~~> Lexer.regex("(Hello)*")).parse(" HelloHelloHello"), "HelloHelloHello")
        }
    }

    static var allTests : [(String, (ParseyTests) -> () throws -> Void)] {
        return [
            ("testIntegers", testIntegers),
        ]
    }
}
