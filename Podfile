# Uncomment this line to define a global platform for your project
platform :ios, "8.0"

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

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Pods-TesSoMe-acknowledgements.plist', 'TesSoMe/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

end

target "TesSoMeTests" do
pod 'AFNetworking'

end

target "Share" do
pod 'AFNetworking'
pod 'SSKeychain'

end

