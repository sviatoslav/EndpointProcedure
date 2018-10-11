/*:
 Usually our connections to backend endpoints have common base URL, requests creation behaviour, response format and response parsing.

 This examle will show how to avoid a boilerplate during implementation of multiple endpoint procedures.
 We'll create procerures for: *<#name>*

 Let's start from inheriting `EndpointProcedureFactory` protocol.
 */
protocol SWProcedureFactory: EndpointProcedureFactory, DefaultConfigurationProvider, HTTPRequestDataBuidlerProvider,
                            BaseURLProvider {}
/*:
 All our procedures will use `Alamofire` for data loading and `JSONDecoder` for response mapping.
 */
import PlaygroundSupport
import Foundation
private enum SWProcedureFactoryStorage {
    static let configuration = Configuration(dataLoadingProcedureFactory: AlamofireProcedureFactory(),
                                             dataDeserializationProcedureFactory: AnyDataDeserializationProcedureFactory { $0 },
                                             responseMappingProcedureFactory: DecodingProcedureFactory(decoder: JSONDecoder()))
}

extension SWProcedureFactory {
    var defaultConfiguration: ConfigurationProtocol {
        return SWProcedureFactoryStorage.configuration
    }
}
/*:
 All our requests will have same base URL.
 */
extension SWProcedureFactory {
    var baseURL: URL {
        return URL(string: "https://swapi.co/api/")!
    }
}
/*:
 Implementation of `CharacterProcedureFactory` will look as follows:
 */
struct Character {
    let name: String
    let vehicles: [URL]
}

extension Character: Decodable {}

struct CharacterProcedureFactory: SWProcedureFactory {
    let id: Int
    func createOrThrow(with configuration: ConfigurationProtocol) throws -> EndpointProcedure<Character> {
        return try EndpointProcedure(requestData: self.builder(for: "people/\(self.id)").build(),
                                     configuration: configuration)
    }
}
/*:
 Conformance to `DefaltConfigurationProvider` allows us to call `create` method without arguments.
 */
var loadedCharacter: Character? = nil
let skywalkerProcedure = CharacterProcedureFactory(id: 1).create()
skywalkerProcedure.addDidFinishBlockObserver { procedure, _ in
    switch procedure.output {
    case .pending: print("No result after finishing")
    case .ready(.success(let character)):
        loadedCharacter = character
        print("Character name: \(character.name)")
    case .ready(.failure(let error)): print("Error: \(error)")
    }
    PlaygroundPage.current.finishExecution()
}
ProcedureQueue.main.add(operation: skywalkerProcedure)
PlaygroundPage.current.needsIndefiniteExecution = true
/*:
 Output of code above:
 ~~~
 Character name: Luke Skywalker
 ~~~
 */
