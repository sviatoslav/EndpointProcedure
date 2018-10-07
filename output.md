`EndpointProcedure` is flexible typesafe bridge between network and application model.
 It's based on [`ProcedureKit`](https://github.com/procedurekit/procedurekit) framework.

 `EndpointProcedure` itself does not perform any requests and does not parse the response, it chains procedures and transfers ouput of one procedure to the next one and uses output of last procedure as own output.

 Data flow looks as follows:

 Loading -> Validation -> Deserialization -> Interception -> Mapping
 - Loading: loads `HTTPResponseData` from any source.
 - Validation: validates `HTTPResponseData`
 - Deserialization: converts loaded `Data` to `Any`
 - Interception: converst deserialized object to format expected by mapping
 - Mapping: Converts `Any` to `Result`

 The easiest way to create instance of `EndpointProcedure` is to creates type that conforms to `EndpointProcedureFactory` protocol.
 This example will show how to use `EndpointProcedure` for loading list of Star Wars films from [Star Wars API](https://swapi.co).

 Let's start from defining `struct Film`.

```swift
import PlaygroundSupport
import Foundation
struct Film {
    let title: String
    let director: String
    let producer: String
    let characters: [URL]
}
```

For `EndpointProcedure` creation we should create new type that conforms to `EndpointProcedureFactory` protocol and implement `createOrThrow(with:)` method.
 
 `cereateOrThrow(with:)` method requires one input parameter of type `ConfigurationProtocol`. `EndpointProcedure.framework` contains struct `Configuration` which conforms to `ConfigurationProtocol`. Initializer of `Configuration` type has 3 input parameters: `HTTPDataLoadingProcedureFactory`, `DataDeserializationProcedureFactory` and `ResponseMappingProcedureFactory`.

 We'll use `AlamofireProcedureFactory` for data loading.

```swift
let loadingFactory = AlamofireProcedureFactory()
```

For response mapping we'll use `DecodingProcedureFactory` with `JSONDecoder`.
 `DecodingProcedureFactory` requires output type to conform `Decodable` protocol.

```swift
extension Film: Decodable {}
let decodingFactory = DecodingProcedureFactory(decoder: JSONDecoder())
```

The aim of data deserialization procedure is converting data loaded by loading procedure into format expected by response mapping procedure.
 `DecodingProcedure` works with plain data, so deserialization should simply return output of data loading procedure.

```swift
let deseriazationFactory = AnyDataDeserializationProcedureFactory(syncDeserialization: {$0})
```

If structure of input expected by mapping procedure is not the same as structure of deserialization procedure's output, we should implement interception procedure.
 In our case, array of films is not root of the response json. It's under "results" key.
 For such cases `DecodingProcedure` accepts input of type `NestedData`.
 
 `NestedData` contains two values `codingPath: [CodingKey]` and `data: Data`

```swift
let interceptionProcedure = TransformProcedure<Any, Any> {
    guard let data = $0 as? Data else { throw ProcedureKitError.requirementNotSatisfied() }
    let codingPath: [AnyCodingKey] = ["results"]
    return NestedData(codingPath: codingPath, data: data)
}
let config = Configuration(dataLoadingProcedureFactory: loadingFactory,
                           dataDeserializationProcedureFactory: deseriazationFactory,
                           responseMappingProcedureFactory: decodingFactory)

struct FilmsEndpointProcedureFactory: EndpointProcedureFactory {
    func createOrThrow(with configuration: ConfigurationProtocol) throws -> EndpointProcedure<[Film]> {
        let url = URL(string: "https://swapi.co/api/films")!
        let data = HTTPRequestData.Builder.for(url).build()
        return EndpointProcedure(requestData: data,
                                 interceptionProcedure: interceptionProcedure,
                                 configuration: configuration)
    }
}

let procedure = FilmsEndpointProcedureFactory().create(with: config)
procedure.addDidFinishBlockObserver { procedure, _ in
    switch procedure.output {
    case .pending: print("No result after finishing")
    case .ready(.success(let films)): print((["Star Wars Films:"] + films.map({ $0.title })).joined(separator: "\n"))
    case .ready(.failure(let error)): print("Error: \(error)")
    }
    PlaygroundPage.current.finishExecution()
}
ProcedureQueue.main.add(operation: procedure)
PlaygroundPage.current.needsIndefiniteExecution = true
```

The output is:

 ```
 Star Wars Films:
 A New Hope
 Attack of the Clones
 The Phantom Menace
 Revenge of the Sith
 Return of the Jedi
 The Empire Strikes Back
 The Force Awakens
 ```