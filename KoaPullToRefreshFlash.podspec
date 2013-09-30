Pod::Spec.new do |s|
  s.name     = 'KoaPullToRefreshFlash'
  s.version  = '1.0.0'
  s.platform = :ios, '6.0'
  s.license  = 'MIT'
  s.summary  = 'Minimal & easily customizable pull-to-refresh control.'
  s.homepage = 'https://github.com/sergigracia/KoaPullToRefresh'
  
  s.author   = { 'Sergi Gracia' => 'sergigram@gmail.com', 'Polina Flegontovna' => 'polina.flegontovna@gmail.com' }
  s.source   = { :git => 'https://github.com/sergigracia/KoaPullToRefresh.git', :tag => s.version.to_s }

  s.description = 'Add this custom, flat, minimal, modern pull-to-refresh ' \
                  'control to your app. You can change the font, colors & size. ' \
                  'This library is very easy to add and customize. ' \
                  'Enjoy.'

  s.frameworks   = 'QuartzCore'
  
  s.source_files = 'KoaPullToRefresh/*.{h,m}'
  s.public_header_files = 'KoaPullToRefresh/*.h'
  s.requires_arc = true
end