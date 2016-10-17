# frozen_string_literal: true
source 'http://rubygems.org'

gemspec

active_record_version = ENV['ACTIVE_RECORD_VERSION'] || 'default'

active_record_opts =
  case active_record_version
  when 'master'
    { github: 'rails/rails' }
  when 'default'
    '~> 5'
  else
    "~> #{active_record_version}"
  end

gem 'activerecord', active_record_opts
