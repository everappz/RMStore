platform :ios, '15.0'

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
