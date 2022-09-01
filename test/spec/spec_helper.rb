require 'easy_extensions/spec_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change
