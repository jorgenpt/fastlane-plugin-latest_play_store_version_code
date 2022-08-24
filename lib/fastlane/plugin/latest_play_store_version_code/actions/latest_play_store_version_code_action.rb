require 'fastlane/action'

module Fastlane
  module Actions
    module SharedValues
      LATEST_PLAY_STORE_VERSION_CODE = :LATEST_PLAY_STORE_VERSION_CODE
      LATEST_PLAY_STORE_RELEASE_NAME = :LATEST_PLAY_STORE_RELEASE_NAME
    end

    class LatestPlayStoreVersionCodeAction < Action
      def self.run(params)
        require 'supply'
        require 'supply/client'

        Supply.config = params
        client = Supply::Client.make_from_config

        client.begin_edit(package_name: Supply.config[:package_name])
        track = client.tracks.find { |track| track.track == params[:track] }
        client.abort_current_edit

        if track.nil?
          UI.error("Could not find the track #{params[:track]} on Google Play, do you need to upload a first build?")
          exit(1)
        end

        release_name = params[:release_name]
        if release_name
          release = track.releases.find { |release| release.name == release_name }
          release_message = "release #{release_name}"
        else
          release = track.releases.last
          release_message = "any releases"
        end

        if release.nil? 
          UI.error("Could not find #{release_message} for #{params[:track]} on Google Play, do you need to upload a first build?")
          exit(1)
        end

        release_name = release.name
        latest_version_code = release.version_codes.last
        if latest_version_code.nil?
          if params[:initial_version_code].nil?
            UI.error("Could not find any version codes for #{release.name} (track '#{params[:track]}') on Google Play.")
            exit(1)
          else
            latest_version_code = params[:initial_version_code].to_s
          end
        end

        Actions.lane_context[SharedValues::LATEST_PLAY_STORE_VERSION_CODE] = latest_version_code.to_i
        Actions.lane_context[SharedValues::LATEST_PLAY_STORE_RELEASE_NAME] = release_name
        return Actions.lane_context[SharedValues::LATEST_PLAY_STORE_VERSION_CODE]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Fetches most recent version code from the Google Play Store"
      end

      def self.details
        [
          "Provides a way to retrieve the latest version code & release name published to Google Play.",
          "Fetches the most recent version code from the given track on Google Play."
        ].join("\n")
      end

      def self.available_options
        require 'supply'
        require 'supply/options'
        options = Supply::Options.available_options.clone
        
        options_to_keep = [:package_name, :track, :json_key, :json_key_data, :key, :issuer, :root_url, :timeout]
        options.delete_if { |option| options_to_keep.include?(option.key) == false }

        options <<  FastlaneCore::ConfigItem.new(key: :release_name,
                                                 env_name: "LATEST_RELEASE_NAME",
                                                 description: "The release name whose latest version code we want",
                                                 optional: true)
        options << FastlaneCore::ConfigItem.new(key: :initial_version_code,
                                                env_name: "INITIAL_VERSION_CODE",
                                                description: "sets the version code to given value if no release is found",
                                                default_value: 1,
                                                skip_type_validation: true) # allow Integer, String
      end

      def self.output
        [
          ['LATEST_PLAY_STORE_VERSION_CODE', 'The latest version code of the latest version of the app uploaded to Google Play'],
          ['LATEST_PLAY_STORE_RELEASE_NAME', 'The release name of the version code']
        ]
      end

      def self.return_value
        "Integer representation of the latest version code uploaded to Google Play Store"
      end

      def self.return_type
        :int
      end

      def self.authors
        ["jorgenpt"]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end

      def self.example_code
        [
          'latest_play_store_version_code(release_name: "1.3")',
        ]
      end

      def self.sample_return_value
        2
      end

      def self.category
        :production
      end
    end
  end
end