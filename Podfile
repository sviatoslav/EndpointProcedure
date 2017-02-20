# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'EndpointProcedure' do
    use_frameworks!
    pod 'ProcedureKit', :git => 'https://github.com/ProcedureKit/ProcedureKit.git', :branch => 'development'

    target 'EndpointProcedureTests' do
        inherit! :search_paths
    end


  target 'AlamofireProcedureFactory' do
      pod 'Alamofire'
      target 'AlamofireProcedureFactoryTests' do
          inherit! :search_paths
          pod 'SwiftyJSON'
      end
  end

    target 'MagicalRecordMappingProcedureFactory' do
        pod 'MagicalRecord'
        target 'MagicalRecordMappingProcedureFactoryTests' do
            inherit! :search_paths
        end
    end

end
