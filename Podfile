
$iOSVersion = '15.0'

platform :ios, $iOSVersion

source 'https://cdn.cocoapods.org/'

install! 'cocoapods', :warn_for_unused_master_specs_repo => false

def shared_pods
  pod 'RMStore', path: '.', subspecs: ['Core', 'KeychainPersistence', 'NSUserDefaultsPersistence', 'AppReceiptVerifier', 'TransactionReceiptVerifier']
  pod 'LSOpenSSL', git: 'git@github.com:everappz/Build-OpenSSL-cURL.git', commit: 'ba0b54b70af02f20ca9d20a6565f576f8f8e3b54'
end

target 'RMStore' do
  shared_pods
end

target 'RMStoreDemo' do
  shared_pods
end

target 'RMStoreTests' do
  shared_pods
end


post_install do |installer|


  #fix xcode 14.3
  #https://stackoverflow.com/questions/75574268/missing-file-libarclite-iphoneos-a-xcode-14-3
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion
      end
    end
  end

end