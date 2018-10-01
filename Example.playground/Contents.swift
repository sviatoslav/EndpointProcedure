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
 */
import Foundation

struct Film: Decodable {
    let title: String
    let director: String
    let producer: String
    let characters: [URL]
}
