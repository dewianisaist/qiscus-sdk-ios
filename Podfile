# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

target 'Example' do
  use_frameworks!

    pod 'Alamofire', '~> 4.0'
    pod 'AlamofireImage'
    pod 'PusherSwift'
    pod 'RealmSwift'
    pod 'SwiftyJSON'
    pod 'ImageViewer'
    pod 'SwiftMQTT'
    pod 'IQAudioRecorderController'
end

target 'Qiscus' do
    use_frameworks!
    
    pod 'Alamofire', '~> 4.0'
    pod 'AlamofireImage'
    pod 'PusherSwift'
    pod 'RealmSwift'
    pod 'SwiftyJSON'
    pod 'ImageViewer'
    pod 'SwiftMQTT'
    pod 'IQAudioRecorderController'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'YES'
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
