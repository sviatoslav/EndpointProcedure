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
 */

