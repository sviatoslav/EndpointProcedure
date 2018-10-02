/*:
 `EndpointProcedure` is flexible typesafe bridge between network and application model.
 It's based on [`ProcedureKit`](https://github.com/procedurekit/procedurekit) framework.
 `EndpointProcedure`.

 `EndpointProcedure` itself does not perform any requests, it chains procedures and transfers ouput of one procedure to the next one and uses output of last procedure as own output.

 Data flow looks as follows:

 Loading -> Validation -> Deserialization -> Interception -> Mapping
 - Loading: loads `HTTPResponseData` from any source.
 - Validation: validates `HTTPResponseData`
 - Deserialization: converts loaded `Data` to `Any`
 - Interception: converst deserialized object to format expected by mapping
 - Mapping: Converts `Any` to `Result`

 The easiest way to create instance of `EndpointProcedure` is to creates type that conforms to `EndpointProcedureFactory` protocol.
 This example will show how to use `EndpointProcedure` for loading data form [Star Wars API](https://swapi.co).

 Let's start from defining `struct Film`.
 */
import PlaygroundSupport
import Foundation
struct Film {
    let title: String
    let director: String
    let producer: String
    let characters: [URL]
}
/*:
 For `EndpointProcedure` creation we should create new type that conforms to `EndpointProcedureFactory` protocol and implement `createOrThrow(with:)` method.
 */
struct FilmsEndpointProcedureFactory: EndpointProcedureFactory {
    func createOrThrow(with configuration: ConfigurationProtocol) throws -> EndpointProcedure<[Film]> {
        let url = URL(string: "https://swapi.co/api/films")!
        let data = HTTPRequestData.Builder.for(url).build()
        return EndpointProcedure(requestData: data, configuration: configuration)
    }
}
/*:
 `cereateOrThrow(with:)` method requires one input parameter of type `ConfigurationProtocol`. `EndpointProcedure.framework` contains struct `Configuration` which conforms to `ConfigurationProtocol`. Initializer of `Configuration` type has 3 input parameters: `HTTPDataLoadingProcedureFactory`, `DataDeserializationProcedureFactory` and `ResponseMappingProcedureFactory`.

 We'll use `AlamofireProcedureFactory` for data loading.
 */
let loadingFactory = AlamofireProcedureFactory()
/*:
 For response mapping we'll use `DecodingProcedureFactory` with `JSONDecoder`.
 `DecodingProcedureFactory` requires `Decodable` type.
 */
extension Film: Decodable {}
let decodingFactory = DecodingProcedureFactory(decoder: JSONDecoder())
/*:
 The aim of data deserialization procedure is converting data loaded by data loading procedure into format expected by response mapping procedure.
 `DecodingProcedure` accepts `Data` or `NestedData` input.
 */
let deseriazationFactory = AnyDataDeserializationProcedureFactory {
    let codingPath: [AnyCodingKey] = ["results"]
    return NestedData(codingPath: codingPath, data: $0)
}

let config = Configuration(dataLoadingProcedureFactory: loadingFactory,
                           dataDeserializationProcedureFactory: deseriazationFactory,
                           responseMappingProcedureFactory: decodingFactory)
let procedure = FilmsEndpointProcedureFactory().create(with: config)
procedure.addDidFinishBlockObserver { procedure, _ in
    switch procedure.output {
    case .pending: print("No result after finishing")
    case .ready(.success(let films)): print(films)
    case .ready(.failure(let error)): print(error)
    }
    PlaygroundPage.current.finishExecution()
}
ProcedureQueue.main.add(operation: procedure)
PlaygroundPage.current.needsIndefiniteExecution = true
