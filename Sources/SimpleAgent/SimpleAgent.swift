import OpenAI
import Foundation

@main struct App {
    static func main() async throws {
        var session = Session()
        try await session.run()
    }
}

struct Session {
    let client = OpenAI(apiToken: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!)
    var previousResponseId: String? = nil

    mutating func run() async throws {
        while true {
            print("You> ", terminator: "")
            guard let line = readLine(), !line.isEmpty else {
                continue
            }
            try await handleInput(input: line)
        }
    }

    mutating func handleInput(input: String) async throws {
        var input = CreateModelResponseQuery.Input.textInput(input)
        while true {
            let response = try await client.responses.createResponse(
                query: .init(
                    input: input,
                    model: "gpt-5",
                    previousResponseId: previousResponseId,
                    tools: MyTool.all()
                )
            )
            previousResponseId = response.id
            var toolInputs: [InputItem] = []
            for output in response.output {
                switch output {
                case .outputMessage(let outputMessage):
                    for content in outputMessage.content {
                        switch content {
                        case .OutputTextContent(let outputTextContent):
                            print("assistant> ", outputTextContent.text)
                        case .RefusalContent(let refusalContent):
                            print("<refusal>")
                        }
                    }
                case .functionToolCall(let call):
                    guard let tool = MyTool(name: call.name, arguments: call.arguments) else { continue }

                    let result = (try? tool.run()) ?? "<error>"
                    toolInputs.append(.item(.functionCallOutputItemParam(.init(callId: call.callId, _type: .functionCallOutput, output: result))))
                    continue
                default:
                    print("not handled")
                }
            }
            guard !toolInputs.isEmpty else {
                break
            }
            input = .inputItemList(toolInputs)
        }
    }
}

enum MyTool {
    case listFiles(path: String)

    init?(name: String, arguments: String) {
        guard name == "list_files" else {
            return nil
        }
        guard let obj = try? JSONSerialization.jsonObject(with: arguments.data(using: .utf8)!), let params = obj as? [String: Any], let path = params["path"], let p = path as? String else {
            return nil
        }
        self = .listFiles(path: p)
    }

    func run() throws -> String {
        switch self {
        case .listFiles(path: let path):
            let fm = FileManager.default
            return try fm.contentsOfDirectory(atPath: path).joined(separator: "\n")
        }
    }

    static func all() -> [Tool] {
        return [
            Tool.functionTool(
                .init(
                    name: "list_files",
                    description: "Lists all the files in a path",
                    parameters: .schema(
                        .type(.object),
                        .properties([
                            "path": .schema(
                                .type(.string),
                                .description("The absolute file path")
                            )
                        ]),
                        .required(["path"]),
                        .additionalProperties(.boolean(false))
                    ),
                    strict: true
                )
            )
        ]
    }
}

