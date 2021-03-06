#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet_x/puppetlabs/dsc_type_helpers'

describe PuppetX::Dsc::TypeHelpers do
  describe "#validate_MSFT_Credential" do

    it "should allow plaintext strings as passwords" do
      cred = { 'user' => 'bob', 'password' => 'password' }
      expect {
        subject.class.validate_MSFT_Credential('foo', cred)
      }.to_not raise_error
    end

    it "should allow Sensitive type passwords" do
      sensitive_pass = Puppet::Pops::Types::PSensitiveType::Sensitive.new('password')
      cred = { 'user' => 'bob', 'password' => sensitive_pass }
      expect {
        subject.class.validate_MSFT_Credential('foo', cred)
      }.to_not raise_error
    end
  end

  describe "#munge_sensitive_hash" do

    it "deserializes and munges malformed sensitive values for Puppet 5" do
      value = SecureRandom.uuid
      hash = {
        "bar" => {"__ptype" => "Sensitive", "__pvalue" => value},
        "bar2" => {
          "bar3" => {"__ptype" => "Sensitive", "__pvalue" => value},
        },
      }
      result = subject.class.munge_sensitive_hash!(hash)
      expect(result["bar"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(result["bar"].unwrap).to eq value
      expect(result["bar2"]["bar3"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(result["bar2"]["bar3"].unwrap).to eq value
    end

    it "deserializes and munges malformed sensitive values for Puppet 6" do
      value = SecureRandom.uuid
      hash = {
        "bar" => {"__pcore_type__" => "Sensitive", "__pcore_value__" => value},
        "bar2" => {
          "bar3" => {"__pcore_type__" => "Sensitive", "__pcore_value__" => value},
        },
      }
      result = subject.class.munge_sensitive_hash!(hash)
      expect(result["bar"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(result["bar"].unwrap).to eq value
      expect(result["bar2"]["bar3"]).to be_a_kind_of Puppet::Pops::Types::PSensitiveType::Sensitive
      expect(result["bar2"]["bar3"].unwrap).to eq value
    end

    it "munges mismatched values and allows validate_MSFT_Credential to run without errors" do
      value = SecureRandom.uuid
      bad_cred = {
        'user' => 'bob',
        'password' => {
          "__pcore_type__" => "Sensitive",
          "__pcore_value__" => value
        }
      }
      puppet5_cred = {
        'user' => 'bob',
        'password' => {
          "__pcore_type__" => "Sensitive",
          "__pcore_value__" => value
        }
      }
      puppet6_cred = {
        'user' => 'bob',
        'password' => {
          "__ptype" => "Sensitive",
          "__pvalue" => value
        }
      }
      subject.class.munge_sensitive_hash!(puppet5_cred)
      subject.class.munge_sensitive_hash!(puppet6_cred)
      expect {
        subject.class.validate_MSFT_Credential('foo', bad_cred)
      }.to raise_error(/should be a String or Sensitive value/)
      expect {
        subject.class.validate_MSFT_Credential('foo', puppet5_cred)
      }.to_not raise_error
      expect {
        subject.class.validate_MSFT_Credential('foo', puppet6_cred)
      }.to_not raise_error
    end
  end
end
