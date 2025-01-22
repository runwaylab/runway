require "./branch_deploy_payload"
require "../lib/to_h"

# The payload class is used as a data structure to hold the data that is passed from event triggers to deployment handlers
# This class is highly flexible and can be used to pass all sorts of data between the two components
# The class is designed to be used as a data structure and should not contain any logic
# Feel free to open a PR and add more fields to this class if you need
class Payload
  include ToH

  getter? ship_it : Bool
  getter? run_post_deploy : Bool
  getter? success : Bool?
  getter sha : String?
  getter ref : String?
  getter tag : String?
  getter environment : String?
  getter repo : String?
  getter production : Bool?
  getter id : String?
  getter status : String?
  getter state : String?
  getter created_at : String?
  getter updated_at : String?
  getter locked : Bool?
  getter timezone : String?
  getter type : String?
  getter url : String?
  getter description : String?
  getter user : String?
  getter path : String?
  getter branch_deploy_payload : BranchDeployPayload?

  # Here is a rough description of what each field *could* be used for
  # All of these fields are optional and can be used as needed - they default to nil
  # @param ship_it [Bool] - A flag to indicate if the deployment was triggered or not - most important field as its used everywhere
  # @param run_post_deploy [Bool] - A flag to indicate if the post_deploy hook should be run or not - this field is also important as it tells the event class that triggered the deployment to run the post_deploy hook or not
  # @param success [Bool or nil] - A flag to indicate if the deployment was successful or not - useful and used frequently in post_deploy hooks
  # @param sha [String or nil] - The commit sha that triggered the deployment or the sha to actually deploy
  # @param ref [String or nil] - The branch or tag that triggered the deployment or the ref to actually deploy
  # @param tag [String or nil] - The tag that triggered the deployment or the tag to actually deploy/use
  # @param environment [String or nil] - The environment that the deployment is targeting or should be deployed to
  # @param repo [String or nil] - The repository that the deployment is targeting or related to
  # @param production [Bool or nil] - A flag to indicate if the deployment is targeting a production environment
  # @param id [String or nil] - The unique identifier for the deployment, probably something like "123abc123" - its a string just in case
  # @param status [String or nil] - The status of the deployment, probably something like "pending" or "success" or "in_progress"
  # @param state [String or nil] - The state of the deployment, probably something like "success" or "failure" or "paused"
  # @param created_at [String or nil] - The timestamp when the deployment was created - hopefully in a format that can be parsed by Time
  # @param updated_at [String or nil] - The timestamp when the deployment was last updated - hopefully in a format that can be parsed by Time
  # @param locked [Bool or nil] - A flag to indicate if the deployment environment is locked or not
  # @param timezone [String or nil] - The timezone that the timestamps (or deployments) are in, probably something like "UTC" or "America/New_York"
  # @param type [String or nil] - The type of deployment, probably something like "deploy" or "rollback" or "promote"
  # @param url [String or nil] - The URL to the deployment or the deployment status page
  # @param description [String or nil] - A description of the deployment or the reason for the deployment
  # @param user [String or nil] - The user that triggered the deployment or the user that is responsible for the deployment
  # @param path [String or nil] - The path to a file that is related to the deployment or the deployment itself
  # @param branch_deploy_payload [BranchDeployPayload or nil] - The branch deploy payload that is related to the deployment - https://github.com/github/branch-deploy/blob/f9cc91d1f3b53149b3abcb582f2844993cd9277d/docs/deployment-payload.md
  def initialize(
    @ship_it : Bool = false,         # defaults to false - set this value to true to indicate that the deployment should be triggered
    @run_post_deploy : Bool = false, # defaults to false - set this value to true to indicate that the post_deploy hook should be run
    @success : Bool? = nil,
    @sha : String? = nil,
    @ref : String? = nil,
    @tag : String? = nil,
    @environment : String? = nil,
    @repo : String? = nil,
    @production : Bool? = nil,
    @id : String? = nil,
    @status : String? = nil,
    @state : String? = nil,
    @created_at : String? = nil,
    @updated_at : String? = nil,
    @locked : Bool? = nil,
    @timezone : String? = nil,
    @type : String? = nil,
    @url : String? = nil,
    @description : String? = nil,
    @user : String? = nil,
    @path : String? = nil,
    @branch_deploy_payload : BranchDeployPayload? = nil
  )
  end

  # This is a helper method to set the ship_it flag to true (or even false) after the Payload object has been created
  setter ship_it : Bool

  # This is a helper method to set the run_post_deploy flag to true (or even false) after the Payload object has been created
  setter run_post_deploy : Bool

  # These are helper methods to set the success flag to true (or even false) after the Payload object has been created
  setter success : Bool?

  setter sha : String?
  setter ref : String?
  setter tag : String?
  setter environment : String?
  setter repo : String?
  setter production : Bool?
  setter id : String?
  setter status : String?
  setter state : String?
  setter created_at : String?
  setter updated_at : String?
  setter locked : Bool?
  setter timezone : String?
  setter type : String?
  setter url : String?
  setter description : String?
  setter user : String?
  setter path : String?
  setter branch_deploy_payload : BranchDeployPayload?
end
