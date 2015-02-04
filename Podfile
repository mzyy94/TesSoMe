# Uncomment this line to define a global platform for your project
platform :ios, "8.1"

target "TesSoMe" do
pod 'AFNetworking'
pod 'REFrostedViewController'
pod 'SSKeychain'
pod 'SDWebImage'
pod 'SWTableViewCell'
pod 'REMenu'
pod 'MPGNotification'
pod 'SVPullToRefresh'
pod 'IDMPhotoBrowser'
pod 'SGNavigationProgress'
pod 'HMSegmentedControl'
pod 'RDVCalendarView'
pod 'DZNEmptyDataSet'
pod 'EAIntroView'
pod 'RSKImageCropper'
pod 'MagicalRecord'
pod 'RMDateSelectionViewController'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-TesSoMe/Pods-TesSoMe-acknowledgements.plist', 'TesSoMe/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

end

target "TesSoMeTests" do
pod 'AFNetworking/Serialization'
pod 'AFNetworking/Security'
pod 'AFNetworking/NSURLConnection'
pod 'AFNetworking/NSURLSession'

end

target "Share" do
pod 'AFNetworking/Serialization'
pod 'AFNetworking/Security'
pod 'AFNetworking/NSURLConnection'
pod 'AFNetworking/NSURLSession'
pod 'SSKeychain'

end

