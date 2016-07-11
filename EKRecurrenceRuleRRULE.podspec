Pod::Spec.new do |s|
s.name     = 'EKRecurrenceRuleRRULE'
s.version  = '1.0.0'
s.homepage = 'https://github.com/lukaszmargielewski/RRULE-to-EKRecurrenceRule.git'
s.license  = 'MIT'
s.platform = :ios
s.source   = { :git => 'https://github.com/lukaszmargielewski/RRULE-to-EKRecurrenceRule.git', :tag => s.version.to_s }
s.source_files = 'EKRecurrenceRuleRRULE/*.{h,m}'
s.requires_arc = true
s.authors = 'Jochen Schöllig'
s.summary = 'Temporary summary'
end
