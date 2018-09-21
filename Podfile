# Uncomment the next line to define a global platform for your project
#platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

target 'EndpointProcedure' do
    platform :ios, '9.0'
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
    
    target 'DecodingProcedureFactory' do
        target 'DecodingProcedureFactoryTests' do
            inherit! :search_paths
        end
    end
end

target 'AlamofireProcedureFactory' do
    platform :ios, '9.0'
    pod 'ProcedureKit'
    pod 'Alamofire'
    target 'AlamofireProcedureFactoryTests' do
        inherit! :search_paths
        pod 'SwiftyJSON'
    end
end

target 'All' do
    platform :osx, '10.13'
    pod 'ProcedureKit'
    pod 'Alamofire'
    pod 'MagicalRecord'
    target 'AllTests' do
        inherit! :search_paths
        pod 'SwiftyJSON'
    end
end
