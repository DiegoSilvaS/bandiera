require 'spec_helper'
require 'rack/test'

describe Bandiera::APIv2 do
  include Rack::Test::Methods

  def app
    Bandiera::APIv2
  end

  before do
    feature_service = Bandiera::FeatureService.new
    feature_service.add_features([
      { group: 'pubserv', name: 'show_subjects', description: '', active: true, user_groups: { list: ['editor'], regex: '' } },
      { group: 'pubserv', name: 'show_metrics', description: '', active: false },
      { group: 'shunter', name: 'stats_logging', description: '', active: true }
    ])
  end

  describe 'GET /all' do
    it 'returns a 200 status' do
      get '/all'
      expect(last_response.status).to eq(200)
    end

    it 'returns a hash of groups, containing a hashes of features / enabled pairs' do
      expected_data = {
        'response' => {
          'pubserv' => {
            'show_subjects' => true,
            'show_metrics' => false
          },
          'shunter' => {
            'stats_logging' => true
          }
        }
      }

      get '/all'
      assert_last_response_matches(expected_data)
    end

    context 'with the URL param "user_group" passed' do
      it 'passes this on to the feature when evaluating if a feature is enabled' do
        # this user_group statisfies the above settings - we expect show_subjects to be true
        get '/all', user_group: 'editor'
        expect(last_response_data['response']['pubserv']['show_subjects']).to be_truthy
      end
    end
  end

  describe 'GET /groups/:group_name/features' do
    it 'returns a 200 status' do
      get '/groups/pubserv/features'
      expect(last_response.status).to eq(200)
    end

    context 'when the group exists' do
      it 'returns a hash of features / enabled pairs' do
        expected_data = {
          'response' => {
            'show_subjects' => true,
            'show_metrics' => false
          }
        }

        get '/groups/pubserv/features'
        assert_last_response_matches(expected_data)
      end

      context 'with the URL param "user_group" passed' do
        it 'passes this on to the feature when evaluating if a feature is enabled' do
          # this user_group statisfies the above settings - we expect show_subjects to be true
          get '/groups/pubserv/features', user_group: 'editor'
          expect(last_response_data['response']['show_subjects']).to be_truthy
        end
      end
    end

    context 'when the group does not exist' do
      before do
        get '/groups/wibble/features'
        @data = JSON.parse(last_response.body)
      end

      it 'returns a 200 status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns an empty data hash' do
        expect(@data['response']).to eq({})
      end

      it 'returns a warning' do
        expect(@data['warning']).to_not be_nil
        expect(@data['warning']).to_not be_empty
      end
    end
  end

  describe 'GET /groups/:group_name/features/:feature_name' do
    it 'returns a 200 status' do
      get '/groups/pubserv/features/show_subjects'
      expect(last_response.status).to eq(200)
    end

    context 'when both the group and feature exist' do
      it 'returns a boolean representing the enabled status' do
        expected_data = { 'response' => false }

        get '/groups/pubserv/features/show_subjects'
        assert_last_response_matches(expected_data)
      end

      context 'with the URL param "user_group" passed' do
        it 'passes this on to the feature when evaluating if a feature is enabled' do
          # this user_group statisfies the above settings - we expect show_subjects to be true
          get '/groups/pubserv/features/show_subjects', user_group: 'editor'
          expect(last_response_data['response']).to be_truthy
        end
      end
    end

    context 'when the group does not exist' do
      before do
        get '/groups/wibble/features/wobble'
        @data = JSON.parse(last_response.body)
      end

      it 'returns a 200 status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns a "false" flag value' do
        expect(@data['response']).to eq(false)
      end

      it 'returns a warning' do
        expect(@data['warning']).to_not be_nil
        expect(@data['warning']).to_not be_empty
      end
    end

    context 'when the feature does not exist' do
      before do
        get '/groups/pubserv/features/wobble'
        @data = JSON.parse(last_response.body)
      end

      it 'returns a 200 status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns a "false" flag value' do
        expect(@data['response']).to eq(false)
      end

      it 'returns a warning' do
        expect(@data['warning']).to_not be_nil
        expect(@data['warning']).to_not be_empty
      end
    end
  end

  private

  def last_response_data
    JSON.parse(last_response.body)
  end

  def assert_last_response_matches(expected_data)
    expect(last_response_data).to eq(expected_data)
  end

end
