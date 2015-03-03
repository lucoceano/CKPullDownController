Pod::Spec.new do |s|
  s.name         = "CKPullDownController"
  s.version      = "1.1"
  s.summary      = "An iOS container view controller for pullable scroll view interfaces."
  s.description  = <<-DESC
  					CKPullDownController is a copy of [MBPullDownController](https://github.com/matej/MBPullDownController) with few bug fix and improviments.
                    CKPullDownController accepts two view controllers, which it presents one above the other.
                    The front view controller is configured to accept a pull interaction which it utilizes to show or hide back view controller.
                   DESC
  s.homepage     = "https://github.com/lucoceano/CKPullDownController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Lucas Martins' => 'lucoceano@gmail.com' }
  s.source       = { :git => "https://github.com/lucoceano/CKPullDownController.git", :tag => s.version.to_s }
  s.source_files = 'CKPullDownController/*.{h,m}'
  s.framework    = "QuartzCore"
  s.platform     = :ios
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
end
