# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'EndpointProcedure' do
    use_frameworks!
    pod 'ProcedureKit'
    
    target 'EndpointProcedureTests' do
        inherit! :search_paths
    end

    target 'MagicalRecordMappingProcedureFactory' do
        pod 'MagicalRecord'
        target 'MagicalRecordMappingProcedureFactoryTests' do
            inherit! :search_paths
        end
    end

end

target 'AlamofireProcedureFactory' do
    use_frameworks!
    pod 'ProcedureKit'
    pod 'Alamofire'
    target 'AlamofireProcedureFactoryTests' do
        inherit! :search_paths
        pod 'SwiftyJSON'
    end
end
